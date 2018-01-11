#!/bin/bash
#
# Rebuild Courier .dat databases and restart Courier MTA.
#
# VERSION       :0.4.2
# DATE          :2016-08-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-mta
# LOCATION      :/usr/local/sbin/courier-restart.sh

Error() {
    echo "ERROR: $*" 1>&2
    exit "$1"
}

set -e

makesmtpaccess || Error $? "smtpaccess/*"

#if ! grep -qFx 'ACCESSFILE=${sysconfdir}/smtpaccess' /etc/courier/esmtpd-msa &&
if grep -qFxi 'ESMTPDSTART=YES' /etc/courier/esmtpd-msa; then
    makesmtpaccess-msa || Error $? "msa smtpaccess/*"
fi

if [ -d /etc/courier/esmtpacceptmailfor.dir ]; then
    makeacceptmailfor || Error $? "esmtp acceptmailfor.dir/*"
fi

if [ -e /etc/courier/hosteddomains ]; then
    makehosteddomains || Error $? "hosted domains"
fi

if [ -f /etc/courier/userdb ]; then
    makeuserdb || Error $? "userdb"
fi

makealiases || Error $? "aliases/*"

# Wait for active courierfilters
if [ -f /run/courier/courierfilter.pid ]; then
    COURIERFILTER_PID="$(head -n 1 /run/courier/courierfilter.pid)"
    FILTER_PIDS="$(pgrep --parent "$COURIERFILTER_PID" || true)"
    if [ -n "$FILTER_PIDS" ]; then
        for PID in ${FILTER_PIDS}; do
            # Wait for running filter children
            while [ -n "$(pgrep --parent "$PID")" ]; do
                echo -n "Filter: "; ps --no-headers -o comm= --pid "$PID"
                sleep 1
            done
        done
    fi
fi

# Restart courier-mta-ssl also
if [ -f /etc/courier/esmtpd-ssl ] && grep -qFxi 'ESMTPDSSLSTART=YES' /etc/courier/esmtpd-ssl; then
    service courier-mta-ssl restart || Error $? "courier-mta-ssl restart"
fi
service courier-mta restart || Error $? "courier-mta restart"

echo "OK."
