#!/bin/bash

INNOBCK_FULL_BACKUP="YYYY-MM-DD"

cd /media/backup || exit 1

TODAY=$(date --rfc-3339=date)

Echo() {
    tty --quiet && echo "$*"
    return 0
}

Echo "etc"
nice tar --one-file-system -cPzf "./etc-backup_${TODAY}.tar.gz" /etc/ || echo "fail: etc" 1>&2
Echo --$?--

# --exclude=
# /etc
# /home
# /run  /var/run
# /var/lib/mysql
# /var/mail
# /var/cache/apt
# /var/cache/???
# /var/spool/???

Echo "fsroot"
nice tar --one-file-system --exclude=/etc --exclude=/run --exclude=/var/cache/apt --exclude=/var/lib/mysql \
    -czPf "./fsroot-backup_${TODAY}.tar.gz" / || echo "fail: fsroot" 1>&2
Echo --$?--

Echo "email"
nice tar --one-file-system -czPf "./email_${TODAY}.tar.gz" /var/mail/ || echo "fail: email" 1>&2
Echo --$?--

Echo "MySQL"
if which innobackupex &> /dev/null; then
    # Full backup first
    #     innobackupex ./sql
    nice innobackupex --incremental ./sql --incremental-basedir="./sql/${INNOBCK_FULL_BACKUP}" \
        || echo "fail: SQL" 1>&2
else
    nice /usr/bin/mysqldump --all-databases --single-transaction --events \
        | nice gzip -1 > "./mysql-All_${TODAY}.sql.gz" || echo "fail: SQL dump" 1>&2
fi
Echo --$?--

exit 0
