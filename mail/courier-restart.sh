#!/bin/bash
#
# Rebuild Courier .dat databases and restart Courier MTA.
#
# VERSION       :0.3.1
# DATE          :2015-11-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta courier-mta-ssl
# LOCATION      :/usr/local/sbin/courier-restart.sh

Error() {
    echo "ERROR: $*"
    exit "$1"
}

makesmtpaccess || Error $? "smtpaccess/*"

#if grep -q '^ACCESSFILE=\${sysconfdir}/smtpaccess$' /etc/courier/esmtpd-msa
if grep -qFx "ESMTPDSTART=YES" /etc/courier/esmtpd-msa; then
    makesmtpaccess-msa || Error $? "esmtpd-msa"
fi

if [ -d /etc/courier/esmtpacceptmailfor.dir ]; then
    makeacceptmailfor || Error $? "esmtpacceptmailfor.dir/*"
fi

if [ -e /etc/courier/hosteddomains ]; then
    makehosteddomains || Error $? "hosteddomains"
fi

if [ -f /etc/courier/userdb ]; then
    makeuserdb || Error $? "userdb"
fi

makealiases || Error $? "aliases/*"

service courier-mta-ssl restart || Error $? "courier-mta-ssl"
service courier-mta restart || Error $? "courier-mta"

echo "OK."
