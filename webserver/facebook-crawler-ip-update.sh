#!/bin/bash
#
# Update Facebook crawler IP ranges.
#
# VERSION       :0.1.0
# DATE          :2021-02-20
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install apache2 whois
# LOCATION      :/usr/local/sbin/facebook-crawler-ip-update.sh
# CRON-DAILY    :/usr/local/sbin/facebook-crawler-ip-update.sh

FACEBOOK_AS="AS32934"
APACHE_CONF_IP="/etc/apache2/conf-available/facebook-crawler-ip.list"

set -e

TEMP_IP="$(mktemp)"
trap 'rm -f "$TEMP_IP"' EXIT HUP INT QUIT PIPE TERM

whois -h whois.radb.net -- "-i origin ${FACEBOOK_AS}" \
    | sed -n -e 's/^route6\?:\s\+\(\S\+\)$/Require ip \1/p' >"$TEMP_IP"

# Check list
if [ ! -s "$TEMP_IP" ] || grep -v -x 'Require ip [0-9a-f:.]\+/[0-9]\+' "$TEMP_IP"; then
    echo "Failed to download Facebook crawler IP ranges" 2>&1
    exit 1
fi

# Detect changes
if diff -q "$APACHE_CONF_IP" "$TEMP_IP"; then
    exit 0
fi

echo "Facebook crawler IP ranges have changed"
# Activate it
mv -f "$TEMP_IP" "$APACHE_CONF_IP"
APACHE_SYNTAX_OK="$(/usr/sbin/apache2ctl configtest 2>&1)"
if [ "$APACHE_SYNTAX_OK" != "Syntax OK" ]; then
    echo "ERROR: Facebook crawler IP change caused Apache syntax error: ${APACHE_SYNTAX_OK}" 1>&2
    exit 2
fi

service apache2 reload >/dev/null

exit 0
