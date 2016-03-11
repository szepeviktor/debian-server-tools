#!/bin/bash
#
# Send interesting parts of syslog of the last hour. Simple logcheck.
#
# VERSION       :0.7.5
# DATE          :2016-01-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install libdate-manip-perl
# DEPENDS       :cpan App:dategrep
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# Use package/dategrep-install.sh

Failures() {
    # -intERRupt,-bERRy, -WARNer, -fail2ban, -MISSy
    grep -Ei "crit|err[^uy]|warn[^e]|fail[^2]|alert|unknown|unable|miss[^y]\
|except|disable|invalid|fault|cannot|denied|broken|exceed|unsafe|unsolicited\
|limit reach|unhandled"
}

# Every hour 17 minutes as in Debian cron.hourly
/usr/local/bin/dategrep --format rsyslog --multiline \
    --from "1 hour ago from -17:00" --to "-17:00" $(ls -tr /var/log/syslog* | tail -n 2) \
    | grep -F -v "$0" \
    | Failures \
    | grep -E -v "error@|spamd\[[0-9]+\]: spamd:|courierd: SHUTDOWN: respawnlo limit reached, system inactive\.$" \
    #| grep -E -v "mysqld: .* Unsafe statement written to the binary log .* Statement:" \
    #| grep -E -v ": 554 Mail rejected|: 535 Authentication failed|>: 451\b" \

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l < /var/log/boot)" -gt 1 ]; then
    # Skip "(Nothing has been logged yet.)"
    sed -e '1!b;/^(Nothing .*$/d' /var/log/boot \
        | /usr/local/bin/dategrep --format "%a %b %e %H:%M:%S %Y" --multiline \
            --from "1 hour ago from -17:00" --to "-17:00" \
        | Failures
fi

exit 0
