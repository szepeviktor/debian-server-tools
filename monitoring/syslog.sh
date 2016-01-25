#!/bin/sh
#
# Follow syslog colorized.
#
# VERSION       :0.2
# DATE          :2015-02-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install ccze
# LOCATION      :/usr/local/sbin/syslog.sh

if ls -l /sbin/init | grep -q "systemd"; then
    LOG_CMD="journalctl -n 300 -f"
else
    LOG_CMD="tail -n 300 -f /var/log/syslog"
fi

${LOG_CMD} \
    | grep -v "imapd:\|imapd\[[0-9]\+\]:\|CRON\[[0-9]\+\]:" \
    | ccze --mode ansi --plugin syslog
