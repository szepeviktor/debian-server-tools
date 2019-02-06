#!/bin/bash
#
# Report cron "grandchild failed" details.
#
# VERSION       :0.2.0
# DATE          :2019-01-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install dategrep
# LOCATION      :/usr/local/sbin/cron-grandchild.sh
# CRON-HOURLY   :/usr/local/sbin/cron-grandchild.sh

Grandchild_pid()
{
    sed -n -e 's|^\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(/USR/SBIN/\)\?CRON\[[0-9]\+\]: (CRON) error (grandchild #\([0-9]\+\) failed with exit status [0-9]\+)$|\2|p'
}

# For non-existent syslog.1
shopt -s nullglob

# Every hour 17 minutes as in Debian cron.hourly, local time (non-UTC)
dategrep --multiline \
    --start "now truncate 1h add -43m" --end "now truncate 1h add 17m" /var/log/syslog.[1] /var/log/syslog \
    | grep -F -v "$0" \
    | Grandchild_pid \
    | while read -r GC_PID; do
        # Search for the log line and add some context
        #     Add markers around it
        grep -C 3 '^\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(/USR/SBIN/\)\?CRON\['"$GC_PID"'\]: (\S\+) CMD (.\+)$' \
            /var/log/syslog.[1] /var/log/syslog \
            | sed 's#^\(\S\+ \+[0-9]\+ [0-9:]\+ \S\+ \(/USR/SBIN/\)\?CRON\['"$GC_PID"'\]: (\S\+) CMD (.\+)\)$#----\n\1\n----#'
    done

exit 0
