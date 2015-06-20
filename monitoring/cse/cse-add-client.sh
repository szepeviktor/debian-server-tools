#!/bin/bash
#
# Add a new can-send-email client.
#
# VERSION       :1.0.0
# DATE          :2015-06-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Prepare .htaccess
IP="$(/sbin/ifconfig | grep -m1 -w -o 'inet addr:[0-9.]*' | cut -d':' -f2)"
read -e -p "Enter management server IP: " -i "$IP" MGMNT || exit 13
sed -i "s/@@IP-REGEXP@@/${MGMNT//./\\\\.}/" .htaccess || exit 14
sed -i "s/@@IP@@/${MGMNT}/" .htaccess || exit 15
sed -i "s/@@IP@@/${MGMNT}/" cse.nginx.conf || exit 16

# Deploy mail sender
SECRET_DIR="$(echo "$RANDOM" | md5sum | cut -d" " -f1)"
echo "lftp -e 'mkdir ${SECRET_DIR}; cd ${SECRET_DIR}; put .htaccess; put cse.php;'"

# Add new host
read -e -p "Enter server name: " HOSTNAME || exit 17
read -e -p "Enter URL: " -i "http://${HOSTNAME}/${SECRET_DIR}/cse.php" URL || exit 18
[ -x ./can-send-email.sh ] && ./can-send-email.sh --add "$HOSTNAME" "$URL"
