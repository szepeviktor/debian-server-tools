#!/bin/bash
#
# Report cron "grandchild failed" details.
#
# VERSION       :0.1.3
# DATE          :2015-11-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install libdate-manip-perl
# DEPENDS       :cpan App:datagrep
# LOCATION      :/usr/local/sbin/cron-grandchild.sh
# CRON-HOURLY   :/usr/local/sbin/cron-grandchild.sh

# Download the dategrep binary directly from GitHub (without package management)
#
#     apt-get install -y libdate-manip-perl
#     R="$(wget -qO- https://api.github.com/repos/mdom/dategrep/releases|sed -n '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')"
#     wget -O /usr/local/bin/dategrep https://github.com/mdom/dategrep/releases/download/${R}/dategrep-standalone-small
#     chmod +x /usr/local/bin/dategrep

Grandchild_pid() {
    sed -n "s/^\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(\/USR\/SBIN\/\)\?CRON\[[0-9]\+\]: (CRON) error (grandchild #\([0-9]\+\) failed with exit status [0-9]\+)$/\1/p"
}

# For non-existent syslog.1
shopt -s nullglob

# Every hour 17 minutes as in Debian cron.hourly, local time (non-UTC)
/usr/local/bin/dategrep --format rsyslog --multiline \
    --from "1 hour ago from -17:00" --to "-17:00" /var/log/syslog.[1] /var/log/syslog \
    | grep -F -v "/usr/local/sbin/syslog-errors.sh" \
    | Grandchild_pid \
    | while read GC_PID; do
        # Search for the log line with some context
        # Add marks around it
        grep -C 3 "^\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(/USR/SBIN/\)\?CRON\[${GC_PID}\]: (\S\+) CMD (.\+)$" \
            /var/log/syslog.[1] /var/log/syslog \
            | sed "s;^\(\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(/USR/SBIN/\)\?CRON\[${GC_PID}\]: (\S\+) CMD (.\+)\)$;----\n\1\n----;"
    done

exit 0
