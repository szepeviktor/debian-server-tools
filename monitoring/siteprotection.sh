#!/bin/bash
#
# List /home files modified in the last hour.
#
# VERSION       :0.2.2
# DATE          :2016-08-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/siteprotection.sh
# CRON.D        :00 *	* * *	root	/usr/local/sbin/siteprotection.sh

# Exclude
#   WordPress cache
#   Joomla cache
#   Joomla admin cache
find /home/ -type f "(" -iname "*.php" -or -iname ".htaccess" ")" -mmin -61 -printf "%p @%TH:%TM:%TS\n" \
    | grep -v -x "/home/[[:alnum:]]\+/website/html/wp-content/cache/.*\.php @[0-9:.]*" \
    | grep -v -x "/home/[[:alnum:]]\+/public_html/server/cache/.*\.php @[0-9:.]*" \
    | grep -v -x "/home/[[:alnum:]]\+/public_html/server/administrator/cache/.*\.php @[0-9:.]*" \

exit 0
