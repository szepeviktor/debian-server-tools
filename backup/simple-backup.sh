#!/bin/bash

BACKUP_DIR="/media/backup/"
INNOBCK_FULL_BACKUP="YYYY-MM-DD"

set -e

Echo() {
    if [ -t 0 ]; then
        echo "$*"
    fi
    return 0
}

Error() {
    echo "Failed: ${*}" 1>&2
}

TODAY="$(date --utc --rfc-3339=date)"

cd "$BACKUP_DIR"

Echo "etc"
nice tar --one-file-system -cPzf "etc-backup_${TODAY}.tar.gz" /etc/ || Error "etc"
Echo "--${?}--"

# --exclude=
# /etc
# /home
# /run /var/run
# /var/lib/mysql
# /var/mail
# /var/cache/apt
# /var/cache/???
# /var/spool/???

Echo "fsroot"
nice tar --exclude=/etc --exclude=/run --exclude=/var/cache/apt --exclude=/var/lib/mysql \
    --one-file-system -czPf "fsroot-backup_${TODAY}.tar.gz" / || Error "fsroot"
Echo "--${?}--"

Echo "email"
nice tar --one-file-system -czPf "email_${TODAY}.tar.gz" /var/mail/ || Error "email"
Echo "--${?}--"

Echo "MySQL"
if which innobackupex &> /dev/null; then
    # Full backup first
    #     innobackupex "sql"
    nice innobackupex --incremental ./sql --incremental-basedir="sql/${INNOBCK_FULL_BACKUP}" \
        || Error "SQL"
else
    nice /usr/bin/mysqldump --all-databases --single-transaction --events \
        | nice gzip -1 > "mysql-alldbs_${TODAY}.sql.gz" || Error "SQL dump"
fi
Echo "--${?}--"

exit 0
