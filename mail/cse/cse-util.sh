#!/bin/bash
#
# Set up can-send-email.
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

# Upload mail sender
echo "Upload directory: "
echo "$RANDOM" | md5sum | cut -d" " -f1
echo "lftp -e 'mkdir SECRET; cd SECRET; put .htaccess; put cse.php;'"

# Create database
./can-send-email.sh --init || exit 16

# Add HTTP server name
read -e -p "Enter server name: " HOSTNAME || exit 17
read -e -p "Enter URL: " URL || exit 18
./can-send-email.sh --add "$HOSTNAME" "$URL"

# Courier alias on management server
echo 'cse@worker.szepe.net:  |/usr/local/sbin/can-send-email.sh'
echo 'editor /etc/courier/aliases/system'
echo 'courier-restart.sh'
