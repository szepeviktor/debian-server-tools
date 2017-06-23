#!/bin/bash
#
# List /home dynamic web files modified in the last hour.
#
# VERSION       :0.3.0
# DATE          :2017-06-22
# IDEA          :https://www.maxer.hu/siteprotection.html
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/siteprotection.sh
# CRON.D        :00 *	* * *	root	/usr/local/sbin/siteprotection.sh

#   Exclude WordPress cache
find /home/ -type f "(" -iname "*.php" -or -iname ".htaccess" ")" "(" -cmin -61 -or -mmin -61 ")" -printf "%p @%TH:%TM:%TS\n" \
    | grep -v -x "/home/[[:alnum:]]\+/website/html/wp-content/cache/.*\.php @[0-9:.]*" \

exit 0
