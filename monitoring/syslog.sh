#!/bin/sh
#
# Show colorized syslog without cron and imapd.
#
# VERSION       :0.3.1
# DATE          :2016-07-14
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install ccze
# LOCATION      :/usr/local/sbin/syslog.sh

if [ "$1" = "-f" ]; then
    FOLLOW="1"
else
    FOLLOW="0"
fi

LOG_OUTPUT=""
if realpath /sbin/init | grep -q "systemd"; then
    if [ "$FOLLOW" = "1" ]; then
        LOG_SOURCE="journalctl -n 300 -f"
    else
        LOG_SOURCE="journalctl"
        LOG_OUTPUT="less -r"
    fi
else
    if [ "$FOLLOW" = "1" ]; then
        LOG_SOURCE="tail -n 300 -f /var/log/syslog"
    else
        LOG_SOURCE="cat /var/log/syslog"
        LOG_OUTPUT="less -r"
    fi
fi

${LOG_SOURCE} \
    | grep -E --line-buffered --invert-match '(imapd|CRON)(\[[0-9]+\])?:' \
    | if [ -z "$LOG_OUTPUT" ]; then
        # ccze (or cat?) holds back some lines with "ccze | cat"
        ccze --mode ansi --plugin syslog
    else
        eval "ccze --mode ansi --plugin syslog | ${LOG_OUTPUT}"
    fi
