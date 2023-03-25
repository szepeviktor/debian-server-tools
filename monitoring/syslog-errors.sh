#!/bin/bash
#
# Send interesting parts of syslog from the last hour. Simple logcheck.
#
# VERSION       :1.0.0
# DATE          :2021-03-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DOCS          :https://www.youtube.com/watch?v=pYYtiIwtQxg
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# TODO More words: https://github.com/raszi/colorize/blob/master/colorize#L21-L22
Filter_failures()
{
    # -intERRupt,-bERRy, -WARNer, -fail2ban, -MISSy, -deFAULT
    grep --extended-regexp --ignore-case "crit|[^f]err[os]|warn[^e]|fail[^2]\
|alert|unknown|unable|miss[^y]|except|disable|invalid|[^e]fault|cannot|denied\
|broken|exceed|too big|too many|unsafe|unsolicited|limit reach|unhandled|traps\
|\\bbad\\b|corrupt|but got status|oom-killer|false|unreach|[^c]oops|ignor[ei]\
|prohibit|timeout|blocked|unavailable|over quota"
}

LOG_EXCERPT="$(mktemp --suffix=.syslog)"

# Search recent log entries
/usr/sbin/logtail2 /var/log/syslog \
    | grep --fixed-strings --invert-match "$0" \
    | Filter_failures \
    > "${LOG_EXCERPT}"

echo "$(wc -l <"${LOG_EXCERPT}") failures total."

while read -r PATTERN; do
    COUNT="$(grep --extended-regexp --count "${PATTERN}" "${LOG_EXCERPT}")"
    if [ "${COUNT}" == 0 ]; then
        continue
    fi
    echo "Ignored: $(printf '%4d' "${COUNT}") × #${PATTERN}#"
done </etc/syslog-errors-excludes.grep

grep --extended-regexp --invert-match --file=/etc/syslog-errors-excludes.grep "${LOG_EXCERPT}" \
    | dd iflag=fullblock bs=1M count=5 2>/dev/null

rm "${LOG_EXCERPT}"

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l </var/log/boot)" -gt 1 ]; then
    # Skip "(Nothing has been logged yet.)"
    /usr/sbin/logtail2 /var/log/boot \
        | sed -e '1!b;/^(Nothing .*$/d' \
        | Filter_failures
fi

exit 0
