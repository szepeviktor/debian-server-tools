#!/bin/bash
#
# Complete MySQL backup daily.
#
# VERSION       :0.1
# DATE          :2014-10-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install util-linux
# LOCATION      :/usr/local/sbin/mysql-backup.sh
# CRON.D        :2 2 * * *  root  /usr/local/sbin/mysql-backup.sh

BACKUP_TARGET="/root/backup/mysql-today.sql.gz"

# Set up /root/.my.cnf [mysqldump] section.

# IO nice and CPU nice
/usr/bin/mysqldump -u root --all-databases --events \
    | ionice -c 3 nice gzip -9 > "$BACKUP_TARGET"
