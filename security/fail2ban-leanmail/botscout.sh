#!/bin/bash
#
# Test missed IP addresses on Botscout API.
#

# Get leanmail hits,
#   exclude them from Fail2ban bans,
#   extract IP addresses,
#   check Botscout API
sed -n -e 's|.*leanmail: .* (\(.*\)) .*|\1|p' /var/log/syslog \
    | grep -vFw -f - /var/log/fail2ban.log \
    | grep -o '\b[0-9.]\{7,15\}\b' | sort -n -u \
    | xargs -I % wget -q -O- "http://botscout.com/test/?ip=%"
