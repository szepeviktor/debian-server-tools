#!/bin/bash
#
# Backup server through SSH filesystem.
#
# VERSION       :1.0.4
# DATE          :2015-11-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install package
# LOCATION      :/usr/local/sbin/system-backup.sh
# OWNER         :root:root
# PERMISSION    :700
# CRON.D        :10 3	* * *	root	/usr/local/sbin/system-backup.sh
# CONFIG        :~/.config/system-backup/configuration

# Usage
#
# Format storage
#     /usr/bin/mkfs.s3ql --authfile "$AUTHFILE" "$STORAGE_URL"
#
# Mount storage
#     backup-web.sh -m
#
# Unmount storage
#     backup-web.sh -u


STORAGE_URL="swiftks://auth.cloud.ovh.net/SBG1:web-olm-s3ql"
RBACKUP="${HOME}/remote-backup"
SSH_KEY="${RBACKUP}/.ssh/id_ecdsa"
SSH_PORT="3220"
TARGET="${RBACKUP}/s3ql-ssh"
AUTHFILE="${RBACKUP}/.s3ql/authinfo2"
REMOTE_ROOT="/home/rs3ql/olm"
REMOTE_TARGET="${REMOTE_ROOT}/s3ql"
# TODO
#source "${HOME}/.config/system-backup/configuration" || ...

Remote_copy() {
    local FROM="$1"
    local TO="$2"

    scp -q -i "$SSH_KEY" -P "$SSH_PORT" \
        "$FROM" "rs3ql@batman.olm.hu:${TO}"
}

Remote_run() {
    ssh -i "$SSH_KEY" -p "$SSH_PORT" \
        rs3ql@batman.olm.hu -- "$@"
}

Mount_sshfs() {
    # TODO --quiet
    if ! sshfs "rs3ql@batman.olm.hu:${REMOTE_TARGET}" "$TARGET" \
        -o IdentityFile="$SSH_KEY" -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -p "$SSH_PORT" -C > /dev/null; then
        Error 41 "SSH mount failed"
    fi
}

Error() {
    local STATUS="$1"
    shift

    echo "ERROR ${STATUS}: $*" 1>&2

    # Umount_sshfs
    if grep -q -w "$TARGET" /proc/mounts; then
        fusermount -u "$TARGET"
    fi
#    if Remote_run /usr/bin/s3qlstat ${S3QL_OPT} "$REMOTE_TARGET" 2> /dev/null; then
    if Remote_run /usr/bin/s3qlstat ${S3QL_OPT} "$REMOTE_TARGET" &> /dev/null; then
        Remote_run /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$REMOTE_TARGET"
        Remote_run /usr/bin/umount.s3ql ${S3QL_OPT} "$REMOTE_TARGET"
    fi

    exit "$STATUS"
}

Check_paths() {
    [ -d "$TARGET" ] || Error 3 "Target does not exist"
    [ -r "$AUTHFILE" ] || Error 4 "Authentication file cannot be read"
    [ -r "$SSH_KEY" ] || Error 5 "SSH key file cannot be read"
}

Check_mount() {
    [ -d "${TARGET}/homes" ] || Error 41 "Target 'homes' dir does not exist"
    [ -d "${TARGET}/email" ] || Error 42 "Target 'email' dir does not exist"
}

List_dbs() {
    echo "SHOW DATABASES;" | mysql --skip-column-names \
        | grep -E -v "information_schema|mysql|performance_schema"
}

Backup_system_dbs() {
    mysqldump --skip-lock-tables mysql > "${TARGET}/mysql-mysql.sql" \
        || Error 5 "MySQL system databases backup failed"
    mysqldump --skip-lock-tables information_schema > "${TARGET}/mysql-information_schema.sql" \
        || Error 6 "MySQL system databases backup failed"
    mysqldump --skip-lock-tables performance_schema > "${TARGET}/mysql-performance_schema.sql" \
        || Error 7 "MySQL system databases backup failed"
}

Check_schemas() {
    local DBS
    local DB
    local SCHEMA
    local TEMP_SCHEMA="$(mktemp)"

    # No `return` within a pipe
    DBS="$(List_dbs)"

    while read -r DB; do
        SCHEMA="${TARGET}/db-${DB}.schema.sql"
        # Check schema
        mysqldump --no-data --skip-comments "$DB" \
            | sed 's/ AUTO_INCREMENT=[0-9]\+\b//' \
            > "$TEMP_SCHEMA" || Error 51 "Schema dump failure"

        if [ -r "$SCHEMA" ]; then
            if ! diff "$SCHEMA" "$TEMP_SCHEMA" 1>&2; then
                echo "Database schema CHANGED for ${DB}" 1>&2
            fi
            rm "$TEMP_SCHEMA"
        else
            mv "$TEMP_SCHEMA" "$SCHEMA" || Error 11 "New schema saving failed for ${DB}"
            echo "New schema created for ${DB}"
        fi
    done <<< "$DBS"
}

Get_base_dir() {
    local BASE
    local XTRAINFO

    ls -tr "${TARGET}/innodb/" \
        | while read -r BASE; do
            XTRAINFO="${TARGET}/innodb/${BASE}/xtrabackup_info"
            # First non-incremental is the base
            if [ -r "$XTRAINFO" ] && grep -qFx "incremental = N" "$XTRAINFO"; then
                echo "$BASE"
                break
            fi
        done
        # No `return` within a pipe
        #return 1
}

Get_latest_dir() {
    local LATEST
    local XTRAINFO

    LATEST="$(find "${TARGET}/innodb/" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"|sort -n|tail -n1)"
    XTRAINFO="${TARGET}/innodb/${LATEST}/xtrabackup_info"

    if [ -r "$XTRAINFO" ] && grep -qx "incremental = [YN]" "$XTRAINFO"; then
        echo "$LATEST"
    fi
}

Backup_innodb() {
    local BASE
    local LATEST

    if [ -d "${TARGET}/innodb" ]; then
        # Get base directory
        BASE="$(Get_base_dir)"
        if [ -z "$BASE" ] || ! [ -d "${TARGET}/innodb/${BASE}" ]; then
            Error 12 "No base InnoDB backup"
        fi
        LATEST="$(Get_latest_dir)"
        if [ -z "$LATEST" ] || ! [ -d "${TARGET}/innodb/${LATEST}" ]; then
            Error 13 "Cannot find latest incremental InnoDB backup"
        fi

        nice innobackupex --throttle=100 --incremental --incremental-basedir="${TARGET}/innodb/${LATEST}" \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 14 "Incremental InnoDB backup failed"
    else
        echo "Creating base InnoDB backup"
        mkdir "${TARGET}/innodb"

        nice innobackupex --throttle=100 \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 15 "First InnoDB backup failed"
    fi
}

Backup_files() {
    # See: Check_mount()

    tar -cPf "${TARGET}/etc-backup_$(date --rfc-3339=date).tar" /etc/

    #strace $(pgrep rsync|sed 's/^/-p /g') 2>&1|grep -F "open("
    rsync -a --delete /home/ "${TARGET}/homes/"

    rsync -a --delete /var/mail/ "${TARGET}/email/"
}

Mount() {
    Remote_copy "${RBACKUP}/.s3ql/authinfo2" "${REMOTE_ROOT}/olm.web.authinfo2"

    Remote_run /usr/bin/mount.s3ql ${S3QL_OPT} --authfile "${REMOTE_ROOT}/olm.web.authinfo2" \
        "$STORAGE_URL" "$REMOTE_TARGET" || Error 1 "Cannot mount storage"

    Remote_run rm -f "${REMOTE_ROOT}/olm.web.authinfo2"

#    Remote_run /usr/bin/s3qlstat ${S3QL_OPT} "$REMOTE_TARGET" 2> /dev/null || Error 2 "Cannot stat storage"
    Remote_run /usr/bin/s3qlstat ${S3QL_OPT} "$REMOTE_TARGET" &> /dev/null || Error 2 "Cannot stat storage"

    Mount_sshfs

    Check_mount
}

Umount() {
    # Umount_sshfs
    # ??? fusermount -u -z "$TARGET" || Error 30 "SSH umount failure"
    fusermount -u "$TARGET" || Error 30 "SSH umount failure"

    Remote_run /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$REMOTE_TARGET" || Error 31 "Flush failed"
    Remote_run /usr/bin/umount.s3ql ${S3QL_OPT} "$REMOTE_TARGET" || Error 32 "Umount failed"
}

# Terminal?
if [ -t 1 ]; then
    read -e -p "Start backup? "
    S3QL_OPT=""
else
    S3QL_OPT="--quiet"
fi

logger -t "system-backup" "Started. $*"

Check_paths

if [ "$1" == "-u" ]; then
    Umount
    exit 0
fi

Mount

if [ "$1" == "-m" ]; then
    exit 0
fi

Backup_system_dbs

Check_schemas

Backup_innodb

Backup_files

Umount

logger -t "system-backup" "Finished. $*"

exit 0
