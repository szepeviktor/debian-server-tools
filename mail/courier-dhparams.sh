#!/bin/bash
#
# Generate Diffie-Hellman parameters for Courier MTA.
#
# VERSION       :0.1.0
# DATE          :2016-04-21
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-ssl
# DOCS          :man mkdhparams
# LOCATION      :/usr/local/sbin/courier-dhparams.sh
# CRON-MONTHLY  :/usr/local/sbin/courier-dhparams.sh

DH_BITS=2048 nice /usr/sbin/mkdhparams 2> /dev/null

if ! [ -r /etc/courier/dhparams.pem ] \
    || ! openssl dhparam -in /etc/courier/dhparams.pem -check > /dev/null; then
    echo "Failed to generate DH params" 2>&1
fi

exit 0
