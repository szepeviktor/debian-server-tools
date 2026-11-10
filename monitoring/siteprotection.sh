#!/bin/bash
#
# List /home critical files modified during the last hour.
#
# VERSION       :0.6.0
# DATE          :2026-11-10
# IDEA          :https://www.maxer.hu/siteprotection.html
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/siteprotection.sh
# CRON.D        :00 *  * * *  root	/usr/local/sbin/siteprotection.sh

# SSH keys
find /home/ -mindepth 3 -maxdepth 3 -type f -path "/home/*/.ssh/authorized_keys" \
    "(" -cmin -61 -o -mmin -61 ")" -printf '%p @%TT\n'

#   Exclude WordPress cache: cache directory, Focus Cache
#   Exclude Laravel view cache: SHA-1, xxHash
#find /home/ -type f "(" -iname "*.php" -o -iname ".js" -o -iname ".htaccess" -o -iname ".env" ")" \
find /home/ -type f "(" -iname "*.php" -o -iname ".htaccess" -o -iname ".env" ")" \
    "(" -cmin -61 -o -mmin -61 ")" -printf '%p @%TT\n' \
    | grep -v -E -x '/home/[[:alnum:]]+/website/code/wp-content/cache/\S+\.php @[0-9:.]+' \
    | grep -v -E -x '/home/[[:alnum:]]+/website/code/wp-content/focus-object-cache/[a-z_-]+/\S+\.php @[0-9:.]+' \
    | grep -v -E -x '/home/[[:alnum:]]+/website/code/storage/framework/views/[0-9a-z]{40}(\.blade)?\.php @[0-9:.]+' \
    | grep -v -E -x '/home/[[:alnum:]]+/website/code/storage/framework/views/[0-9a-z]{32}(\.blade)?\.php @[0-9:.]+' \

exit 0
