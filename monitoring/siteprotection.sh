#!/bin/bash
#
# List /home files modified in the last 24 hours.
#
# VERSION       :0.1.0
# DATE          :2015-12-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/siteprotection.sh
# CRON-DAILY    :/usr/local/sbin/siteprotection.sh

find /home/ -type f "(" -iname "*.php" -or -iname ".htaccess" ")" -mtime -1 \
    grep -vx "/home/[[:alnum:]]\+/website/html/wp-content/cache/.*\.php" \
    grep -vx "/home/[[:alnum:]]\+/public_html/server/administrator/cache/.*\.php" \

exit 0
