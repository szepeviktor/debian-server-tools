#!/bin/bash
#
# Add a new can-send-email PHP client.
#
# VERSION       :1.1.0
# DATE          :2015-12-05
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Prepare .htaccess in place
IP="$(ip addr show dev eth0|sed -n 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"
read -e -p "Enter management server IP: " -i "$IP" MGMNT || exit 13
sed -i "s/@@IP-REGEXP@@/${MGMNT//./\\\\.}/" .htaccess || exit 14
sed -i "s/@@IP@@/${MGMNT}/" .htaccess || exit 15
sed -i "s/@@SERVER-NAME@@/$(host -t PTR "$MGMNT" | sed 's/^.* //')/" .htaccess || exit 15
sed -i "s/@@IP@@/${MGMNT}/" cse.nginx.conf || exit 16
sed -i "s/@@SERVER-NAME@@/$(host -t PTR "$MGMNT" | sed 's/^.* //')/" cse.nginx.conf || exit 15

# Deploy mail sender
OBSCURE_DIR="$(echo "$RANDOM" | md5sum | cut -d " " -f 1)"
echo "lftp -e 'mkdir ${OBSCURE_DIR}; cd ${OBSCURE_DIR}; put .htaccess; put cse.php;'"

# Add new host
read -e -p "Enter server hostname: " HOSTNAME || exit 17
read -e -p "Enter URL: " -i "http://${HOSTNAME}/${OBSCURE_DIR}/cse.php" URL || exit 18
[ -x ./can-send-email.sh ] && ./can-send-email.sh add "$HOSTNAME" "$URL"
