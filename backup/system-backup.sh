#!/bin/bash
#
# Backup a server with S3QL.
#
# VERSION       :2.0.7
# DATE          :2016-07-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install debconf-utils s3ql rsync mariadb-client-10.0 percona-xtrabackup
# DOCS          :https://www.percona.com/doc/percona-xtrabackup/2.3/innobackupex/incremental_backups_innobackupex.html
# LOCATION      :/usr/local/sbin/system-backup.sh
# OWNER         :root:root
# PERMISSION    :700
# CI            :shellcheck -e SC2086 system-backup.sh
# CRON.D        :10 3	* * *	root	/usr/local/sbin/system-backup.sh
# CONFIG        :/root/.config/system-backup/configuration

# Usage
#
# Create S3QL configuration file
#     mkdir /root/.s3ql; editor /root/.s3ql/authinfo2; chmod 0600 /root/.s3ql/authinfo2
#
# Example S3QL configuration for Swift
#     [provider]
#     storage-url: STORAGE_URL/CONTAINER
#     backend-login: OS_TENANT_NAME:OS_USERNAME
#     backend-password: OS_PASSWORD
#     fs-passphrase: $(apg -m32 -n1)
#
# Create configuration file
#     mkdir /root/.config/system-backup; editor /root/.config/system-backup/configuration
#
# Example configuration
#     #STORAGE_URL="local:///media/backup-server.sshfs"
#     #STORAGE_URL="s3://BUCKET/PREFIX_"
#     STORAGE_URL="swiftks://auth.cloud.ovh.net/OS_REGION_NAME:CONTAINER/PREFIX_"
#     TARGET="/media/server-backup.s3ql"
#     #MOUNT_OPTIONS="--threads 4 --compress zlib-5"
#     AUTHFILE="/root/.s3ql/authinfo2"
#     DB_EXCLUDE="excluded-db1|excluded-db2"
#     HCHK_UUID="aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb"
#
# Add an [xtrabackup] section to /root/.my.cnf
#     editor /root/.my.cnf
#
# Format storage
#     /usr/bin/mkfs.s3ql "$STORAGE_URL"
#
# Save encryption master key!
#
# Create target directory
#     mkdir "$TARGET"
#
# Excluded path example in /home
#     /user/website/session/
#
# Mount storage manually
#     system-backup.sh -m
#
# Save /root files to "${TARGET}/_root"
#
# Unmount storage
#     system-backup.sh -u

CONFIG="/root/.config/system-backup/configuration"
HOME_EXCLUDE_LIST="/root/.config/system-backup/exclude.list"

Onexit() {
    local -i RET="$1"
    local BASH_CMD="$2"

    set +e

    if [ "$RET" -ne 0 ]; then
        #if /usr/bin/s3qlstat ${S3QL_OPT} "$TARGET" &> /dev/null; then
        if [ -e "${TARGET}/.__s3ql__ctrl__" ]; then
            /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$TARGET"
            /usr/bin/umount.s3ql ${S3QL_OPT} "$TARGET"
        fi

        echo "COMMAND: ${BASH_CMD}" 1>&2
    fi

    exit "$RET"
}

Error() {
    local STATUS="$1"

    set +e

    shift

    echo "ERROR ${STATUS}: $*" 1>&2

    exit "$STATUS"
}

Rotate_weekly() {
    local DIR="$1"
    local -i PREVIOUS

    if [ -z "$DIR" ]; then
        Error 60 "No directory to rotate"
    fi

    if ! [ -d "${TARGET}/${DIR}/6" ]; then
        mkdir "${TARGET}/${DIR}"/{0..6} 1>&2 || Error 61 "Cannot create weekday directories"
    fi

    PREVIOUS="$((CURRENT_DAY - 1))"
    if [ "$PREVIOUS" -lt 0 ]; then
        PREVIOUS="6"
    fi

    /usr/bin/s3qlrm ${S3QL_OPT} "${TARGET}/${DIR}/${CURRENT_DAY}" 1>&2 \
        || Error 62 "Failed to remove current day's directory"
    /usr/bin/s3qlcp ${S3QL_OPT} "${TARGET}/${DIR}/${PREVIOUS}" "${TARGET}/${DIR}/${CURRENT_DAY}" 1>&2 \
        || Error 63 "Cannot duplicate last daily backup"

    # Return current directory
    echo "${TARGET}/${DIR}/${CURRENT_DAY}"
}

Check_paths() {
    [ -r "$AUTHFILE" ] || Error 4 "Authentication file cannot be read"
    [ -d "$TARGET" ] || Error 3 "Target does not exist"
}

List_dbs() {
    echo "SHOW DATABASES;" | mysql --skip-column-names \
        | grep -E -v "information_schema|mysql|performance_schema"
}

Backup_system_dbs() {
    if ! [ -d "${TARGET}/db-system" ]; then
        mkdir "${TARGET}/db-system" || Error 44 "Failed to create 'db-system' directory in target"
    fi

    mysqldump --skip-lock-tables mysql > "${TARGET}/db-system/mysql-mysql.sql" \
        || Error 5 "MySQL system databases backup failed"
    mysqldump --skip-lock-tables information_schema > "${TARGET}/db-system/mysql-information_schema.sql" \
        || Error 6 "MySQL system databases backup failed"
    mysqldump --skip-lock-tables performance_schema > "${TARGET}/db-system/mysql-performance_schema.sql" \
        || Error 7 "MySQL system databases backup failed"
}

Check_db_schemas() {
    local DBS
    local DB
    local SCHEMA
    local TEMP_SCHEMA

    TEMP_SCHEMA="$(mktemp)"

    # `return` is not available within a pipe
    DBS="$(List_dbs)"

    if ! [ -d "${TARGET}/db" ]; then
        mkdir "${TARGET}/db" || Error 43 "Failed to create 'db' directory in target"
    fi
    while read -r DB; do
        if [ -n "$DB_EXCLUDE" ] && [[ "$DB" =~ ${DB_EXCLUDE} ]]; then
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
            rm -f "$TEMP_SCHEMA"
        else
            mv "$TEMP_SCHEMA" "$SCHEMA" || Error 11 "New schema saving failed for ${DB}"
            echo "New schema created for ${DB}"
        fi
    done <<< "$DBS"
}

Get_base_db_backup_dir() {
    local BACKUP_DIRS
    local XTRAINFO

    # shellcheck disable=SC2012
    BACKUP_DIRS="$(ls -tr "${TARGET}/innodb")"
    while read -r BASE; do
        XTRAINFO="${TARGET}/innodb/${BASE}/xtrabackup_info"
        # First non-incremental is the base
        if [ -r "$XTRAINFO" ] && grep -q -F -x "incremental = N" "$XTRAINFO"; then
            echo "$BASE"
            return 0
        fi
    done <<< "$BACKUP_DIRS"
    return 1
}

Backup_innodb() {
    local BASE
    local -i ULIMIT_FD
    local -i MYSQL_TABLES

    ULIMIT_FD="$(ulimit -n)"
    MYSQL_TABLES="$(find /var/lib/mysql/ -type f | wc -l)"
    MYSQL_TABLES+="10"
    if [ "$ULIMIT_FD" -lt "$MYSQL_TABLES" ]; then
        ulimit -n "$MYSQL_TABLES"
    fi
    if [ -d "${TARGET}/innodb" ]; then
        # Get base directory
        # @TODO Use last incremental as base?
        BASE="$(Get_base_db_backup_dir)"
        if [ -z "$BASE" ] || ! [ -d "${TARGET}/innodb/${BASE}" ]; then
            Error 12 "No base InnoDB backup"
        fi
        innobackupex --throttle=100 --incremental --incremental-basedir="${TARGET}/innodb/${BASE}" \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 13 "Incremental InnoDB backup failed"
    else
        # Create base backup
        echo "Creating base InnoDB backup"
        mkdir "${TARGET}/innodb"
        innobackupex --throttle=100 \
            "${TARGET}/innodb" \
            2>> "${TARGET}/innodb/backupex.log" || Error 14 "Base InnoDB backup failed"
    fi
    # Check OK message
    tail -n 1 "${TARGET}/innodb/backupex.log" | grep -q -F ' completed OK!' \
        || Error 15 "InnoDB backup operation not OK"
}

Backup_files() {
    local WEEKLY_ETC
    local WEEKLY_HOME
    local WEEKLY_MAIL
    local WEEKLY_USR
    declare -a HOME_EXCLUDE

    # /etc
    if ! [ -d "${TARGET}/etc" ]; then
        mkdir "${TARGET}/etc" || Error 40 "Failed to create 'etc' directory in target"
    fi
    WEEKLY_ETC="$(Rotate_weekly etc)"
    if [ -z "$WEEKLY_ETC" ] || ! [ -d "$WEEKLY_ETC" ]; then
        Error 41 "Failed to create weekly directory for 'etc'"
    fi
    tar --exclude=.git -cPf "${WEEKLY_ETC}/etc-backup.tar" /etc/
    # Save debconf data
    debconf-get-selections > "${WEEKLY_ETC}/debconf.selections"
    dpkg --get-selections > "${WEEKLY_ETC}/packages.selections"
    # Make directory tree immutable
    /usr/bin/s3qllock ${S3QL_OPT} "$WEEKLY_ETC"

    # /home
    if ! [ -d "${TARGET}/homes" ]; then
        mkdir "${TARGET}/homes" || Error 42 "Failed to create 'homes' directory in target"
    fi
    WEEKLY_HOME="$(Rotate_weekly homes)"
    #strace $(pgrep rsync|sed 's/^/-p /g') 2>&1|grep -F "open("
    if [ -z "$WEEKLY_HOME" ] || ! [ -d "$WEEKLY_HOME" ]; then
        Error 43 "Failed to create weekly directory for 'home'"
    fi
    # Exclude file
    if [ -r "$HOME_EXCLUDE_LIST" ]; then
        HOME_EXCLUDE=( "--exclude-from=${HOME_EXCLUDE_LIST}" )
    fi
    ionice rsync "${HOME_EXCLUDE[@]}" -a --delete /home/ "$WEEKLY_HOME"
    # Make directory tree immutable
    /usr/bin/s3qllock ${S3QL_OPT} "$WEEKLY_HOME"

    # /var/mail
    if ! [ -d "${TARGET}/email" ]; then
        mkdir "${TARGET}/email" || Error 44 "Failed to create 'email' directory in target"
    fi
    WEEKLY_MAIL="$(Rotate_weekly email)"
    if [ -z "$WEEKLY_MAIL" ] || ! [ -d "$WEEKLY_MAIL" ]; then
        Error 45 "Failed to create weekly directory for 'mail'"
    fi
    ionice rsync -a --delete /var/mail/ "$WEEKLY_MAIL"
    # Make directory tree immutable
    /usr/bin/s3qllock ${S3QL_OPT} "$WEEKLY_MAIL"

    # /usr/local
    if ! [ -d "${TARGET}/usr" ]; then
        mkdir "${TARGET}/usr" || Error 46 "Failed to create 'usr' directory in target"
    fi
    WEEKLY_USR="$(Rotate_weekly usr)"
    if [ -z "$WEEKLY_USR" ] || ! [ -d "$WEEKLY_USR" ]; then
        Error 47 "Failed to create weekly directory for 'usr'"
    fi
    ionice rsync --exclude="/src/" -a --delete /usr/local/ "$WEEKLY_USR"
    # Make directory tree immutable
    /usr/bin/s3qllock ${S3QL_OPT} "$WEEKLY_USR"
}

Mount() {
    [ -z "$(find "$TARGET" -mindepth 1 -maxdepth 1)" ] || Error 5 "Target directory is not empty"

    # "If the file system is marked clean and not due for periodic checking, fsck.s3ql will not do anything."
    /usr/bin/fsck.s3ql ${S3QL_OPT} "$STORAGE_URL" 1>&2 || test $? == 128

    nice /usr/bin/mount.s3ql ${S3QL_OPT} ${MOUNT_OPTIONS} \
        "$STORAGE_URL" "$TARGET" || Error 1 "Cannot mount storage"

    /usr/bin/s3qlstat ${S3QL_OPT} "$TARGET" &> /dev/null || Error 2 "Cannot stat storage"
}

Umount() {
    /usr/bin/s3qlctrl ${S3QL_OPT} flushcache "$TARGET" || Error 31 "Flush failed"
    /usr/bin/umount.s3ql ${S3QL_OPT} "$TARGET" || Error 32 "Umount failed"
}

declare -i CURRENT_DAY

set -e

trap 'Onexit "$?" "$BASH_COMMAND"' EXIT HUP INT QUIT PIPE TERM

CURRENT_DAY="$(date --utc "+%w")"

# On terminal?
if [ -t 1 ]; then
    read -r -s -e -p "Start backup? "
    echo
    S3QL_OPT=""
else
    S3QL_OPT="--quiet"
fi

# Read configuration
[ -r "$CONFIG" ] || Error 100 "Unconfigured"
# shellcheck disable=SC1090
source "$CONFIG"

logger -t "system-backup" "Started. $*"

Check_paths

if [ "$1" == "-u" ]; then
    Umount
    exit 0
fi

Mount

if [ "$1" == "-m" ]; then
    echo "cd ${TARGET}/"
    exit 0
fi

Backup_system_dbs

Check_db_schemas

Backup_innodb

Backup_files

Umount

# Log file: /root/.s3ql/mount.log
logger -t "system-backup" "Finished. $*"

if [ -n "$HCHK_UUID" ]; then
    wget -q -t 3 -O- "https://hchk.io/${HCHK_UUID}" | grep -q -F -x "OK"
fi

exit 0
