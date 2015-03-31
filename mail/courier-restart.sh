#!/bin/bash
#
# Rebuild Courier .dat databases and restart Courier MTA.
#
# VERSION       :0.3
# DATE          :2015-02-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta courier-mta-ssl
# LOCATION      :/usr/local/sbin/courier-restart.sh

Error() {
    echo "ERROR: $*"
    exit $1
}

makesmtpaccess || Error $? "smtpaccess/*"
#grep -q '^ACCESSFILE=\${sysconfdir}/smtpaccess$' /etc/courier/esmtpd-msa || makesmtpaccess-msa || Error $? "esmtpd-msa"
grep -q '^ESMTPDSTART=YES$' /etc/courier/esmtpd-msa || makesmtpaccess-msa || Error $? "esmtpd-msa"
! [ -d /etc/courier/esmtpacceptmailfor.dir ] || makeacceptmailfor || Error $? "esmtpacceptmailfor.dir/*"
! [ -e /etc/courier/hosteddomains ] || makehosteddomains || Error $? "hosteddomains"
! [ -f /etc/courier/userdb ] || makeuserdb || Error $? "userdb"
makealiases || Error $? "aliases/*"
service courier-mta-ssl restart || Error $? "courier-mta-ssl"
service courier-mta restart || Error $? "courier-mta"

echo "OK."
