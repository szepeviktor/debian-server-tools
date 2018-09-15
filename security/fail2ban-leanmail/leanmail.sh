#!/bin/bash
#
# Don't send Fail2ban notification emails of IP-s with records.
#
# VERSION       :1.0.0
# DATE          :2018-09-14
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :/usr/local/bin/ip-reputation.sh
# LOCATION      :/usr/local/sbin/leanmail.sh

# Usage and remarks
#
# Make sure your MTA runs as "courier" user
#     (source /etc/courier/esmtpd >/dev/null; echo "$MAILUSER")
# Pipe destination address into leanmail.sh in MTA config
#     f2bleanmail: |/usr/local/sbin/leanmail.sh admin@example.com
# Set destination for Fail2ban address in jail.local
#     destemail = f2bleanmail
# Create configuration file read permission for MTA
#     install -o courier -g courier -m 0400 /dev/null /var/lib/courier/.config/ip-reputation/configuration
# Create cache directory read/write permission for MTA
#     sudo -u courier -- mkdir -p /var/lib/courier/.cache/ip-reputation
# Prepend X-Fail2ban header to your action in sendmail-*.local
#     actionban = printf %%b "X-Fail2ban: <ip>,<sender>
# Restart fail2ban
#     fail2ban-client reload
#
# Testing
#     cd /tmp; echo "X-Fail2ban: 127.0.0.2,admin@szepe.net" | time sudo -u courier -- bash -x leanmail.sh
#
# Serving a website over HTTPS reduces number of attacks!

DEST="${1:-admin@szepe.net}"

set -e

# Parse piped email
# Strip "Received:" headers
FIRST_LINE=""
while [ -z "$FIRST_LINE" ] \
    || [ "${FIRST_LINE#Received: }" != "$FIRST_LINE" ] \
    || [ "${FIRST_LINE#DKIM-Signature: }" != "$FIRST_LINE" ] \
    || [ "${FIRST_LINE#Authentication-Results: }" != "$FIRST_LINE" ] \
    || [ "${FIRST_LINE:0:1}" == " " ] || [ "${FIRST_LINE:0:1}" == $'\t' ]; do
    # Reads from pipe
    IFS="" read -r FIRST_LINE
done
# Find X-Fail2ban header containing IP address
if ! grep -q -x 'X-Fail2ban: [0-9a-fA-F:.]\+,\S\+@\S\+' <<<"$FIRST_LINE"; then
    # Delivery message when X-Fail2ban header is missing
    # Reads from pipe
    sed -e "1s#^#${FIRST_LINE}\\n#" | /usr/sbin/sendmail "$DEST"
    exit 99
fi

# X-Fail2ban: <ip>,<sender>
IP_SENDER="${FIRST_LINE#X-Fail2ban: }"
IP="${IP_SENDER%%,*}"

# Check IP reputation
# @FIXME courier-mta sets HOME to "/etc/courier/aliases"
if HOME="/var/lib/courier" /usr/local/bin/ip-reputation.sh "$IP"; then
    exit 99
fi

# Report IP
#sed -e '/\(bad_request_post_user_agent_empty\|no_wp_here_\)/{s//\1/;h};${x;/./{x;q0};x;q1}'
#wget -q -O- --post-data="auth=$(echo -n "${IP}${INSTANT_SECRET}"|shasum -a 256|cut -d" " -f1)&ip=${IP}" \
#    https://DOMAIN/dnsbl.php &>/dev/null &

# Deliver message: From: sender, To: destination
# Reads from pipe
/usr/sbin/sendmail -f "${IP_SENDER##*,}" "$DEST"

exit 99
