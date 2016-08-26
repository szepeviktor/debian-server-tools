#!/bin/bash
#
# Simple system backup.
#
# VERSION       :0.2.2
# DATE          :2016-08-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install debconf-utils sshfs percona-xtrabackup
# CRON.D        :10 3	* * *	root	/usr/local/sbin/simple-backup.sh

BACKUP_DIR="/media/backup"
#BACKUP_DIR="/media/backup.ssh"
INNOBCK_FULL_BACKUP="YYYY-MM-DD"

declare -i CURRENT_DAY

Echo() {
    if [ -t 0 ]; then
        echo "$*"
    fi
    return 0
}

Error() {
    echo "Failed: ${*}" 1>&2
}

set -e

CURRENT_DAY="$(date --utc "+%w")"

Echo "mount"
! grep -w "$BACKUP_DIR" /proc/mounts
#sshfs -p $PORT "${SHFS_USER}@${SSHFS_HOST}:backup/${CURRENT_DAY}" "${BACKUP_DIR}" -o IdentityFile="/root/backup/id_ecdsa" -o idmap=user
cd "$BACKUP_DIR"

Echo "fsroot"
# --exclude=
# /etc
# /home
# /run /var/run
# /var/lib/mysql
# /var/mail
# /var/cache/apt
# /var/cache/???
# /var/spool/???
nice tar --exclude=/etc --exclude=/run --exclude=/var/cache/apt --exclude=/var/lib/mysql \
    --one-file-system -czPf "${CURRENT_DAY}/fsroot.tar.gz" / || Error "fsroot"

Echo "etc+debcong"
nice tar --one-file-system -cPzf "${CURRENT_DAY}/etc.tar.gz" /etc/ || Error "etc"
debconf-get-selections > "${CURRENT_DAY}/debconf.selections"
dpkg --get-selections > "${CURRENT_DAY}/packages.selections"

Echo "usr"
nice tar --one-file-system -cPzf "${CURRENT_DAY}/usr.tar.gz" /usr/local/ || Error "usr"

Echo "Email"
nice tar --one-file-system -czPf "${CURRENT_DAY}/email.tar.gz" /var/mail/ || Error "Email"

Echo "MySQL"
if which innobackupex &> /dev/null; then
    # Full backup first
    #     innobackupex "sql"
    nice innobackupex --incremental ./sql --incremental-basedir="sql/${INNOBCK_FULL_BACKUP}" \
        || Error "SQL"
else
    nice /usr/bin/mysqldump --all-databases --single-transaction --events \
        | nice gzip -1 > "${CURRENT_DAY}/mysql-alldbs.sql.gz" || Error "SQL dump"
fi

Echo "WordPress"
nice tar --one-file-system -cPzf "${CURRENT_DAY}/${WP_SITE}-wp-files.tar.gz" "$DOC_ROOT" || Error "WP files"
sudo -u broadbandly -- /usr/local/bin/wp --path="$ABSPATH" db dump - \
    | nice gzip -1 > "${CURRENT_DAY}/${WP_SITE}-wp.sql.gz" || Error "WP db"

cd /
#Echo "umount"
#umount "$BACKUP_DIR"

#wget -q -t 3 -O- "https://hchk.io/${UUID}" | grep -Fx "OK"

exit 0
