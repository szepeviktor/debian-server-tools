#!/bin/bash
#
# Email interesting parts of the syslog (one hour up to the current hour 17 minutes).
#
# Mini logcheck.
#
# VERSION       :0.3
# DATE          :2015-03-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install -y libdate-manip-perl
# DEPENDS       :cpan App:datagrep
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# every hour 17 minutes as Debian cron.hourly, non-UTC, local time
/usr/local/bin/dategrep --format rsyslog --multiline --from "1 hour ago from -17:00" --to "-17:00" /var/log/syslog \
    | egrep -i "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" \
    | grep -v -i "intERRupt" \
    | grep -v "/usr/local/sbin/syslog-errors\.sh"
    #| grep -v "554 Mail rejected\|535 Authentication failed"

exit 0
