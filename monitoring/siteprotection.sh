#!/bin/bash
#
# List /home files modified in the last hour.
#
# VERSION       :0.2.0
# DATE          :2016-08-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/siteprotection.sh
# CRON.D        :00 *	* * *	root	/usr/local/sbin/siteprotection.sh

set -e

# Exclude
#   WordPress cache
#   Joomla cache
find /home/ -type f "(" -iname "*.php" -or -iname ".htaccess" ")" -mmin -61 \
    | grep -v -x "/home/[[:alnum:]]\+/website/html/wp-content/cache/.*\.php" \
    | grep -v -x "/home/[[:alnum:]]\+/public_html/server/cache/.*\.php" \
    | grep -v -x "/home/[[:alnum:]]\+/public_html/server/administrator/cache/.*\.php" \

exit 0
