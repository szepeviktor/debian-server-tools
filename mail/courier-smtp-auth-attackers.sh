#!/bin/bash
#
# List SMTP authentication attackers by CIDR /24
#

sed -n -e 's#.*courieresmtpd: error,relay=::ffff:\(\S\+\),msg="535 Authentication failed\.".*#\1#p' /var/log/syslog \
    | sortip | cut -d "." -f 1-3 | uniq -c -d
