#!/bin/bash
#
# Report statistics about Fail2ban leanmail
#
# VERSION       :0.1.0
# DATE          :2015-10-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/leanmail-hits.sh
# CRON.D        :29 6	* * *	root	/usr/local/sbin/leanmail-hits.sh

sed -ne 's/^.* fail2ban-leanmail: .* \(\S\+\)$/\1/p' /var/log/syslog \
    | sort | uniq -c \
    | sort -n
