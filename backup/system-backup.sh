#!/bin/bash
#
# Backup a server.
#
# VERSION       :1.1.1
# DATE          :2015-12-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mariadb-client-10.0 s3ql rsync
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
#     system-backup.sh -m
#
# Unmount storage
#     system-backup.sh -u

DB_EXCLUDE="excluded-db1|excluded-db2"
TARGET="/media/s3ql-provider"
STORAGE_URL="swiftks://auth.cloud.ovh.net/SBG1:company.server.s3ql"
AUTHFILE="/root/.s3ql/authinfo2"

Error() {
    local STATUS="$1"
    shift

    echo "ERROR ${STATUS}: $*" 1>&2

    #if /usr/bin/s3qlstat ${S3QL_OPT} "$TARGET" &> /dev/null; then
    if [ -e "${TARGET}/.__s3ql__ctrl__" ]; then
        /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$TARGET"
        /usr/bin/umount.s3ql ${S3QL_OPT} "$TARGET"
    fi

    exit "$STATUS"
}

Rotate_weekly() {
    local DIR="$1"
    local -i CURRENT="$(date --utc "+%w")"
    local -i PREVIOUS

    if [ -z "$DIR" ]; then
        Error 60 "No directory to rotate"
    fi

    if ! [ -d "${TARGET}/${DIR}/6" ]; then
        mkdir -p "${TARGET}/${DIR}"/{0..6} 1>&2 || Error 61 "Cannot create weekly directories"
    fi

    PREVIOUS="$((CURRENT - 1))"
    if [ "$PREVIOUS" -lt 0 ]; then
        PREVIOUS="6"
    fi

    /usr/bin/s3qlrm ${S3QL_OPT} "${TARGET}/${DIR}/${CURRENT}" 1>&2 \
        || Error 62 "Failed to remove current weekly directory"
    /usr/bin/s3qlcp ${S3QL_OPT} "${TARGET}/${DIR}/${PREVIOUS}" "${DIR}/${CURRENT}" 1>&2 \
        || Error 63 "Cannot duplicate last weekly backup"

    # Return current directory
    echo "${TARGET}/${DIR}/${CURRENT}"
}

Check_paths() {
    [ -d "$TARGET" ] || Error 3 "Target does not exist"
    [ -r "$AUTHFILE" ] || Error 4 "Authentication file cannot be read"
}

List_dbs() {
    echo "SHOW DATABASES;" | mysql --skip-column-names \
        | grep -E -v "information_schema|mysql|performance_schema"
}

Check_mount() {
    [ -d "${TARGET}/homes" ] || Error 41 "Target 'homes' dir does not exist"
    [ -d "${TARGET}/email" ] || Error 42 "Target 'email' dir does not exist"
    [ -d "${TARGET}/innodb" ] || Error 43 "Target 'innodb' dir does not exist"
    [ -d "${TARGET}/db" ] || Error 44 "Target 'db' dir does not exist"
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
        if [[ "$DB" =~ ${DB_EXCLUDE} ]]; then
            continue
        fi

        SCHEMA="${TARGET}/db/db-${DB}.schema.sql"
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
    local XTRAINFO

    ls -tr "${TARGET}/innodb" \
        | while read -r BASE; do
            XTRAINFO="${TARGET}/innodb/${BASE}/xtrabackup_info"
            # First non-incremental is the base
            if [ -r "$XTRAINFO" ] && grep -qFx "incremental = N" "$XTRAINFO"; then
                echo "$BASE"
                return 0
            fi
        done
        return 1
}

Backup_innodb() {
    local BASE

    if [ -d "${TARGET}/innodb" ]; then
        # Get base directory
        BASE="$(Get_base_dir)"
        if [ -z "$BASE" ] || ! [ -d "${TARGET}/innodb/${BASE}" ]; then
            Error 12 "No base InnoDB backup"
        fi
        nice innobackupex --throttle=100 --incremental --incremental-basedir="${TARGET}/innodb/${BASE}" \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 13 "Incremental InnoDB backup failed"
    else
        # Create base
        echo "Creating base InnoDB backup"
        mkdir "${TARGET}/innodb"
        nice innobackupex --throttle=100 \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 14 "First InnoDB backup failed"
    fi
}

Backup_files() {
    # See: Check_mount()
    local WEEKLY_ETC
    local WEEKLY_HOME
    local WEEKLY_MAIL

    WEEKLY_ETC="$(Rotate_weekly "etc")"
    tar -cPf "${WEEKLY_ETC}/etc-backup.tar" /etc/

    WEEKLY_HOME="$(Rotate_weekly "homes")"
    #strace $(pgrep rsync|sed 's/^/-p /g') 2>&1|grep -F "open("
    rsync -a --delete /home/ "$WEEKLY_HOME"

    WEEKLY_MAIL="$(Rotate_weekly "email")"
    rsync -a --delete /var/mail/ "$WEEKLY_MAIL"
}

Mount() {
    # "If the file system is marked clean and not due for periodic checking, fsck.s3ql will not do anything."
    /usr/bin/fsck.s3ql ${S3QL_OPT} "$STORAGE_URL" 1>&2

    /usr/bin/mount.s3ql ${S3QL_OPT} \
        "$STORAGE_URL" "$TARGET" || Error 1 "Cannot mount storage"

    /usr/bin/s3qlstat ${S3QL_OPT} "$TARGET" &> /dev/null || Error 2 "Cannot stat storage"

    Check_mount
}

Umount() {
    /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$TARGET" || Error 31 "Flush failed"
    /usr/bin/umount.s3ql ${S3QL_OPT} "$TARGET" || Error 32 "Umount failed"
}

# Terminal?
if [ -t 1 ]; then
    read -e -p "Start backup? "
    S3QL_OPT=""
else
    S3QL_OPT="--quiet"
fi

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

exit 0
