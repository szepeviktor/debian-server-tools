#!/bin/bash
#
# Send interesting parts of syslog from the last hour. Simple logcheck.
#
# VERSION       :0.8.1
# DATE          :2016-04-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

Failures() {
    # -intERRupt,-bERRy, -WARNer, -fail2ban, -MISSy
    grep -Ei "crit|err[^uy]|warn[^e]|fail[^2]|alert|unknown|unable|miss[^y]\
|except|disable|invalid|fault|cannot|denied|broken|exceed|unsafe|unsolicited\
|limit reach|unhandled"
}

# Search recent log entries
/usr/sbin/logtail2 /var/log/syslog \
    | grep -F -v "$0" \
    | Failures \
    | grep -E -v "error@|spamd\[[0-9]+\]: spamd:|courierd: SHUTDOWN: respawnlo limit reached, system inactive\.$" \
    | grep -E -v "couriertls: connect: .*:SSL routines:(SSL3_GET_CLIENT_HELLO|SSL3_GET_RECORD):(unsupported protocol|wrong version number|no shared cipher)$" \
    #| grep -E -v "mysqld: .* Unsafe statement written to the binary log .* Statement:" \
    #| grep -E -v ": 554 Mail rejected|: 535 Authentication failed|>: 451\b" \

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l < /var/log/boot)" -gt 1 ]; then
    # Skip "(Nothing has been logged yet.)"
    /usr/sbin/logtail2 /var/log/boot \
        | sed -e '1!b;/^(Nothing .*$/d' \
        | Failures
fi

exit 0
