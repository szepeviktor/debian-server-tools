#!/bin/bash
#
# Add a new can-send-email PHP client.
#
# VERSION       :1.2.0
# DATE          :2015-12-05
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

set -e

IP="$(ip addr show dev eth0 | sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"
read -r -e -p "Enter management server IP: " -i "$IP" MGMNT

# .htaccess
sed -i -e "s/@@IP-REGEXP@@/${MGMNT//./\\\\.}/" .htaccess
sed -i -e "s/@@IP@@/${MGMNT}/" .htaccess
sed -i -e "s/@@SERVER-NAME@@/$(host -t PTR "$MGMNT" | sed 's/^.* //')/" .htaccess

# nginx.conf
sed -i -e "s/@@IP@@/${MGMNT}/" cse.nginx.conf
sed -i -e "s/@@SERVER-NAME@@/$(host -t PTR "$MGMNT" | sed 's/^.* //')/" cse.nginx.conf

# Deploy instructions
OBSCURE_DIR="$(head -c 100 /dev/urandom | md5sum | cut -d " " -f 1)"
echo "lftp -e 'mkdir ${OBSCURE_DIR}; cd ${OBSCURE_DIR}; put .htaccess; put cse.php;'"

# Add new host to cse
read -r -e -p "Enter server hostname: " HOSTNAME
read -r -e -p "Enter URL: " -i "http://${HOSTNAME}/${OBSCURE_DIR}/cse.php" URL
test -x ./can-send-email.sh && ./can-send-email.sh add "$HOSTNAME" "$URL"
