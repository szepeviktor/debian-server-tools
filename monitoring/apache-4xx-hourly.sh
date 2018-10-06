#!/bin/bash
#
# Report Apache client and server errors of the last hour.
#
# VERSION       :0.1.0
# DATE          :2017-01-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/apache-4xx-hourly.sh
# CRON.D        :59 *  * * *  root	/usr/local/sbin/apache-4xx-hourly.sh

THIS_HOUR="$(date "+%d/%b/%Y:%H")"
ERRORS="$(grep -E -H "\\[${THIS_HOUR}:.+\\] \".+\" (4(0[0-9]|1[0-7])|50[0-5]) [0-9]+ \"" /var/log/apache2/*access*.log)"

if [ "$(wc -l <<<"$ERRORS")" -gt 20 ]; then
    echo "More than 20 apache errors per hour" 1>&2
    echo "$ERRORS"
fi

exit 0
