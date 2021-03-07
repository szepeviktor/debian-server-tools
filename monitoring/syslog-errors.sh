#!/bin/bash
#
# Send interesting parts of syslog from the last hour. Simple logcheck.
#
# VERSION       :0.9.0
# DATE          :2021-03-04
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DOCS          :https://www.youtube.com/watch?v=pYYtiIwtQxg
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# TODO More words: https://github.com/raszi/colorize/blob/master/colorize#L21-L22
Failures()
{
    # -intERRupt,-bERRy, -WARNer, -fail2ban, -MISSy, -deFAULT
    grep -E -i "crit|[^f]err[os]|warn[^e]|fail[^2]|alert|unknown|unable|miss[^y]\
|except|disable|invalid|[^e]fault|cannot|denied|broken|exceed|too big|too many|unsafe\
|unsolicited|limit reach|unhandled|traps|\\bbad\\b|corrupt|but got status|oom-killer\
|false|unreach|[^c]oops|ignor[ei]|prohibit|timeout|blocked|unavailable|over quota"
}

# Search recent log entries
/usr/sbin/logtail2 /var/log/syslog \
    | grep -F -v "$0" \
    | dd iflag=fullblock bs=1M count=5 2>/dev/null \
    | Failures \
    | grep --extended-regexp --invert-match --file=/etc/syslog-errors-excludes.grep

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l </var/log/boot)" -gt 1 ]; then
    # Skip "(Nothing has been logged yet.)"
    /usr/sbin/logtail2 /var/log/boot \
        | sed -e '1!b;/^(Nothing .*$/d' \
        | Failures
fi

exit 0
