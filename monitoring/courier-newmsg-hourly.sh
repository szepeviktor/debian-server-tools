#!/bin/bash
#
# Alert on increased number of messages in the last hour.
#
# VERSION       :0.1.0
# DATE          :2017-03-14
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/courier-newmsg-hourly.sh
# CRON.D        :59 *	* * *	root	/usr/local/sbin/courier-newmsg-hourly.sh

MAX_MESSAGES="100"

THIS_HOUR="$(date "+%b %d %H")"
# Does not handle logrotates
MESSAGES="$(grep -E -H "^${THIS_HOUR}:.+ courierd: newmsg," /var/log/syslog)"

if [ "$(wc -l <<< "$MESSAGES")" -gt "$MAX_MESSAGES" ]; then
    echo "More than ${MAX_MESSAGES} emails per hour" 1>&2
    echo "$MESSAGES"
fi

exit 0
