#!/bin/bash
#
# Generate Diffie-Hellman parameters for Courier MTA.
#
# VERSION       :0.5.1
# DATE          :2018-07-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta
# DOCS          :man mkdhparams
# LOCATION      :/usr/local/sbin/courier-dhparams.sh
# CRON-MONTHLY  :/usr/local/sbin/courier-dhparams.sh

# man 8 mkdhparams
DH_BITS=medium nice /usr/sbin/mkdhparams 2>/dev/null

if [ ! -r /etc/courier/dhparams.pem ] \
    || ! openssl dhparam -in /etc/courier/dhparams.pem -check -noout &>/dev/null; then
    echo "Failed to generate DH params" 1>&2
    exit 1
fi

# Reload monit
if [ "$(dpkg-query --showformat='${Status}' --show monit 2>/dev/null)" == "install ok installed" ]; then
    service monit reload >/dev/null
fi

exit 0
