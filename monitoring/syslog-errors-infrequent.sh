#!/bin/bash
#
# Send interesting parts of syslog from the last 3 hours. Simple logcheck.
#
# VERSION       :0.8.9
# DATE          :2016-04-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DOCS          :https://www.youtube.com/watch?v=pYYtiIwtQxg
# DEPENDS       :apt-get install logtail
# LOCATION      :/usr/local/sbin/syslog-errors-infrequent.sh
# CRON.D        :17 */3	* * *	root	/usr/local/sbin/syslog-errors-infrequent.sh

Failures() {
    # -intERRupt,-bERRy, -WARNer, -fail2ban, -MISSy, -deFAULT
    grep -Ei "crit|err[os]|warn[^e]|fail[^2]|alert|unknown|unable|miss[^y]\
|except|disable|invalid|[^e]fault|cannot|denied|broken|exceed|too big|unsafe|unsolicited\
|limit reach|unhandled|traps|\bbad\b|corrupt"
}

# Search recent log entries
/usr/sbin/logtail2 /var/log/syslog \
    | grep -F -v "$0" \
    | Failures \
    | grep -E -v "rngd\[[0-9]+\]: stats: FIPS 140-2 failures: [0-9]+\$" \
    | grep -E -v "courierd: SHUTDOWN: respawnlo limit reached, system inactive\.\$" \
    #| grep -E -v "couriertls: (accept|connect): error:[0-9A-F]+:SSL routines:SSL2?3_GET_(CLIENT_HELLO|RECORD):(unknown protocol|unsupported protocol|wrong version number)\$" \
    #| grep -E -v "couriertls: (accept|connect): error:[0-9A-F]+:SSL routines:SSL2?3_GET_(CLIENT_HELLO|RECORD):(no shared cipher|unknown protocol|unsupported protocol|wrong version number)\$" \
    #| grep -E -v ": 554 Mail rejected|: 535 Authentication failed|>: 451\b" \
    #| grep -E -v "spamd\[[0-9]+\]: spamd:|error@" \
    #| grep -E -v "courieresmtpd: error,relay=.*(: 451 4\.7\.1 Please try another MX\$|,msg=\"535 Authentication rejected\",cmd:)" \
    #| grep -E -v "mysqld: .* Unsafe statement written to the binary log .* Statement:" \
    #| grep -F -v "/usr/bin/php -d error_reporting=22517 -d disable_functions=error_reporting" \

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l < /var/log/boot)" -gt 1 ]; then
    # Skip "(Nothing has been logged yet.)"
    /usr/sbin/logtail2 /var/log/boot \
        | sed -e '1!b;/^(Nothing .*$/d' \
        | Failures
fi

exit 0
