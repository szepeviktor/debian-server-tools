#!/bin/bash

TODAY=$(date --rfc-3339=date)

cd /media/backup || exit 1

Echo() {
    tty --quiet && echo "$*"
    return 0
}

Echo "/etc"
nice tar --one-file-system -cPzf "./etc-backup_${TODAY}.tar.gz" /etc/ || echo "fail: /etc" >&2
Echo --$?--

# --exclude=
# /etc
# /home
# /var/cache/apt
# /var/lib/mysql
# /run (/var/run)
# /var/mail
# /var/cache/???
# /var/spool/???

Echo "/ (root)"
nice tar --one-file-system --exclude=/etc --exclude=/run --exclude=/var/cache/apt --exclude=/var/lib/mysql \
    -czPf "./fsroot-backup_${TODAY}.tar.gz" / || echo "fail: /" >&2
Echo --$?--

Echo "/var/mail"
nice tar --one-file-system -czPf "./email_${TODAY}.tar.gz" /var/mail/ || echo "fail: mail" >&2
Echo --$?--

Echo "MySQL"
if which innobackupex &> /dev/null; then
    # full backup
    #innobackupex ./sql
    INNOBCK_BASE="mysql-All_<FULL-BACKUP-DATE>"
    nice innobackupex --incremental ./sql --incremental-basedir="./sql/${INNOBCK_BASE}" \
        || echo "fail: SQL" >&2
else
    /usr/bin/mysqldump --all-databases --single-transaction --events \
        | nice gzip -1 > "./mysql-All_${TODAY}.sql.sz" || echo "fail: SQL" >&2
fi
Echo --$?--

exit 0
