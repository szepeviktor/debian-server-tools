#!/bin/bash
#
# Rebuild Courier gdbm databases and restart Courier MTA.
#
# VERSION       :1.0.0
# DATE          :2018-01-20
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

if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' courier-mta)" lt "0.75.0-15"; then
    echo "This restart script is for new init scripts using init-d-script" 1>&2
    #wget "https://github.com/szepeviktor/debian-server-tools/raw/35fe029cc3260bb27393bdb90ea0d75c69727083/mail/courier-restart.sh"
    exit 100
fi

# Recreate gdbm databases

makesmtpaccess || Error $? "smtpaccess/*"
# if catconf /etc/courier/smtpaccess/* | grep -v -x '\S\+\s\S\+'; then Error $? "smtpaccess syntax"; fi

if [ -d /etc/courier/esmtpacceptmailfor.dir ]; then
    makeacceptmailfor || Error $? "esmtp acceptmailfor.dir/*"
fi

# File or directory
if [ -e /etc/courier/hosteddomains ]; then
    makehosteddomains || Error $? "hosted domains"
fi

if [ -f /etc/courier/userdb ]; then
    makeuserdb || Error $? "userdb"
fi

makealiases || Error $? "aliases/*"
# if catconf /etc/courier/aliases/* | grep -v -E -x '\S+:\s*\S+|\S+:\s*\|.+|\S+:\s*\S+,.+'; then Error $? "alias syntax"; fi


# Restart services

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
service courierfilter restart || Error $? "courierfilter restart"

service courier restart || Error $? "courier (outbound) restart"

service courier-mta restart || Error $? "courier-mta restart"

if [ -f /etc/courier/esmtpd-ssl ] && grep -q -F -x -i 'ESMTPDSSLSTART=YES' /etc/courier/esmtpd-ssl; then
    service courier-mta-ssl restart || Error $? "courier-mta-ssl restart"
fi

# @FIXME Detect different access file
# if ! grep -qFx 'ACCESSFILE=${sysconfdir}/smtpaccess' /etc/courier/esmtpd-msa &&
if [ -f /etc/courier/esmtpd-msa ] && grep -q -F -x -i 'ESMTPDSTART=YES' /etc/courier/esmtpd-msa; then
    makesmtpaccess-msa || Error $? "msa smtpaccess/*"
    service courier-msa restart || Error $? "courier-msa restart"
fi

echo "OK."
