#!/bin/bash

exit 0

weekly
grep "courieresmtpd: .*: 5[0-9][0-9] " "/var/log/mail.log.1" | grep -wv "554" \
    | mailx -s "[admin] incoming mail errors" postmaster


#
# Report a service's filtered log from yesturday.
#
# VERSION       :1.0.0
# DATE          :2015-07-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze recode
# LOCATION      :/usr/local/sbin/service-log-report.sh.sh
# CRON-DAILY    :/usr/local/sbin/service-log-report.sh.sh

# Installation
#
# Use package/dategrep-install.sh
#
# - Set date format in `dategrep --format`
# - Set filter regexp in Filter_log()
# - Set email recipient and subject
# - Copy to /usr/local/sbin/CUSTOM-NAME-log-report.sh
# - And add cron job

SERVICE_LOG=""
EMAIL_ADDRESS="admin@szepe.net"
EMAIL_SUBJECT="[ad.min] SERVICE log from $(hostname -f)"

Filter_log() {
    # Courier SMTP: /var/log/mail.log
    grep " courieresmtpd: .*\(: 523 Message length ([0-9]\+ bytes) exceeds administrative limit\.$\|534 SIZE=Message too big\)\
 courierfilter: .*[Ee]xception"
    # fail2ban: /var/log/fail2ban.log
    #grep ": ERROR "
}

if [ -z "$SERVICE_LOG" ]; then
    exit 99
fi

# Date formats
#
# - Syslog: --format syslog
# - Courier SMTP: "Dec  1 23:59:59 server courieresmtpd:" '%b %e %T'
# - fail2ban: "2015-07-03 02:54:07,143 fail2ban.filter : ERROR  Unable to open" '%Y-%m-%d %T(,[0-9]+)?'
# - boot log: "Thu Jun  4 23:00:15 2015: Starting Courier SMTP/SSL server: done." '%a %b %e %H:%M:%S %Y'
# https://metacpan.org/pod/distribution/Date-Manip/lib/Date/Manip/Date.pod#PRINTF-DIRECTIVES

ionice -c 3 /usr/local/bin/dategrep --format '%b %e %T' --multiline \
    --from "1 day ago at 06:25:00" --to "06:25:00" "${SERVICE_LOG}.1" "$SERVICE_LOG" \
    | Filter_log \
    | sed "s;^;$(basename "$SERVICE_LOG" .log): ;g" \
    | mailx -E -S from="service log <root>" -s "$EMAIL_SUBJECT" "$EMAIL_ADDRESS"
