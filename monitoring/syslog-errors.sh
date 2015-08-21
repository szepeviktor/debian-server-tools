#!/bin/bash
#
# Send interesting parts of syslog of the last hour. Simple logcheck.
#
# VERSION       :0.5.6
# DATE          :2015-08-20
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
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep

Failures() {
    # -intERRupt, -fail2ban
    grep -E -i "crit|err[^u]|warn|fail[^2]|alert|unknown|unable|miss|except|disable|invalid|cannot|denied|broken|exceed"
}

# Every hour 17 minutes as in Debian cron.hourly, local time (non-UTC)
/usr/local/bin/dategrep --format rsyslog --multiline \
    --from "1 hour ago from -17:00" --to "-17:00" $(ls -tr /var/log/syslog* | tail -n 2) \
    | grep -F -v "/usr/local/sbin/syslog-errors.sh" \
    | Failures \
    #| grep -v "554 Mail rejected\|535 Authentication failed"

# Run every three hours
#
#    --from "3 hour ago from -17:00" --to "-17:00" $(ls -tr /var/log/syslog* | tail -n 2) \
#    --from "3 hour ago from -17:00" --to "-17:00" /var/log/boot \
#
# CRON.D        :17 */3	* * *	root	/usr/local/sbin/syslog-errors.sh

# Process boot log
if [ -s /var/log/boot ] && [ "$(wc -l < /var/log/boot)" -gt 1 ]; then
    /usr/local/bin/dategrep --format "%a %b %e %H:%M:%S %Y" --multiline \
        --from "1 hour ago from -17:00" --to "-17:00" /var/log/boot \
        | Failures
fi

exit 0
