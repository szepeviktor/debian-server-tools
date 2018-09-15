#!/bin/bash
#
# Report statistics about Fail2ban leanmail.
#
# VERSION       :0.2.0
# DATE          :2018-09-15
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/leanmail-hits.sh
# CRON.D        :29 6	* * *	root	/usr/local/sbin/leanmail-hits.sh

sed -n -e 's/^.* ip-reputation: .* matches \(\S\+\)$/\1/p' /var/log/syslog \
    | sort | uniq -c \
    | sort -n
