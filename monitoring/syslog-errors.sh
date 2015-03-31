#!/bin/bash
#
# Cron job to email one hour of syslog up to the current hour 17 minutes.
# Use for watching a production system after some changes.
#
# VERSION       :0.1
# DATE          :2014-12-29
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install -y libdate-manip-perl
# LOCATION      :/usr/local/sbin/syslog-errors.sh
# CRON-HOURLY   :/usr/local/sbin/syslog-errors.sh

# non-UTC
THIS17DATE="$(date "+%Y-%m-%d %H:17:00")"
declare -i THIS17SEC="$(date --date="$THIS17DATE" "+%s")"
declare -i PREV17SEC="$(( THIS17SEC - 3600 ))"
PREVDATE="$(date --date="@${PREV17SEC}" "+%Y-%m-%d %H:%M:%S")"

# see: monitoring/README.md
dategrep --format rsyslog --multiline --from "$PREVDATE" --to "$THIS17DATE" /var/log/syslog \
    | egrep -i "crit|err|warn|fail[^2]|alert|unkn|miss|except|disable|invalid|cannot|denied" \
    | grep -v -i "intERRupt"
    #| grep -v "554 Mail rejected\|535 Authentication failed"

exit 0
