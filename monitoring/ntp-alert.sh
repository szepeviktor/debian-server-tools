#!/bin/bash
#
# Check system time and alert on offset greater than 128 ms.
#
# VERSION       :0.1.1
# DATE          :2016-03-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install ntpdate bc
# LOCATION      :/usr/local/bin/ntp-alert.sh
# CRON-DAILY    :/usr/local/bin/ntp-alert.sh

NTP_POOL="0.europe.pool.ntp.org"

Die() {
    local RET="$1"

    shift
    echo -e "[ERROR] $*" 1>&2
    exit "$RET"
}

OFFSET="$(/usr/sbin/ntpdate -q "$NTP_POOL" | sed -ne '0,/^.*: \(adjust\|step\) time server [0-9a-f.:]\+ offset \(-\?[0-9.]\+\) sec$/s//\2/p')"

if [ -z "$OFFSET" ]; then
    Die 1 "Failed to measure offset"
fi

# Absolute milisecond offset
OFFSET_MSEC="$(echo "( ${OFFSET#-} * 1000 )/1" | bc -q)"

if [ "$OFFSET_MSEC" -gt 128 ]; then
    Die 2 "The measured offset is greater than +-128 ms."
fi

exit 0
