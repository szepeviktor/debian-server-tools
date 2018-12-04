#!/bin/bash
#
# Complete MySQL backup daily.
#
# VERSION       :0.1.0
# DATE          :2014-10-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install util-linux
# LOCATION      :/usr/local/sbin/mysql-backup.sh
# CRON.D        :2 2  * * *  root /usr/local/sbin/mysql-backup.sh
# CONFIG        :~/.my.cnf [mysqldump] section

BACKUP_TARGET="/root/backup/mysql-today.sql.gz"

# CPU nice
/usr/bin/mysqldump --all-databases --single-transaction --events \
    | gzip -9 >"$BACKUP_TARGET"
