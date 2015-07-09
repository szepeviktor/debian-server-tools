#!/bin/bash
#
# Send interesting parts of syslog of the last hour. Simple logcheck.
#
# VERSION       :0.5.0
# DATE          :2015-06-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install -y libdate-manip-perl
# DEPENDS       :cpan App:datagrep
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# Download the dategrep binary directly from GitHub (without package management)
#
#     apt-get install -y libdate-manip-perl
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/s//\1/p')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep

Failures() {
    grep -E -i "crit|err|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied"
}

# Every hour 17 minutes as in Debian cron.hourly, non-UTC, local time
/usr/local/bin/dategrep --format rsyslog --multiline \
    --from "1 hour ago from -17:00" --to "-17:00" /var/log/syslog \
    | grep -F -v "/usr/local/sbin/syslog-errors.sh" \
    | Failures \
    | grep -F -v -i "intERRupt" \
    #| grep -v "554 Mail rejected\|535 Authentication failed"

# Process boot log
/usr/local/bin/dategrep --format "%a %b %e %H:%M:%S %Y" --multiline \
    --from "1 hour ago from -17:00" --to "-17:00" /var/log/boot \
    | grep -F -v "/usr/local/sbin/syslog-errors.sh" \
    | Failures

exit 0
