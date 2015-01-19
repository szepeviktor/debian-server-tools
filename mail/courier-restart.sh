#!/bin/bash
#
# Rebuild Courier .dat databases and restart Courier MTA.
#
# VERSION       :0.1
# DATE          :2015-01-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta courier-mta-ssl

Error() {
    echo "ERROR: $*"
    exit $1
}

makesmtpaccess || Error $? "smtpaccess/*"
makesmtpaccess-msa || Error $? "esmtpd-msa"
makeacceptmailfor || Error $? "esmtpacceptmailfor.dir/*"
makehosteddomains || Error $? "hosteddomains"
! [ -f /etc/courier/userdb ] || makeuserdb || Error $? "userdb"
makealiases || Error $? "aliases/*"
service courier-mta-ssl restart || Error $? "courier-mta-ssl"
service courier-mta restart || Error $? "courier-mta"

echo "OK."
