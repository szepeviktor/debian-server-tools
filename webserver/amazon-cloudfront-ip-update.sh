#!/bin/bash
#
# Update Amazon CloudFront IP ranges for mod_remoteip.
#
# VERSION       :0.2.0
# DATE          :2018-09-29
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# REFS          :/etc/apache2/mods-available/remoteip.conf
# DEPENDS       :apt-get install apache2 jq
# LOCATION      :/usr/local/sbin/amazon-cloudfront-ip-update.sh
# CRON-DAILY    :/usr/local/sbin/amazon-cloudfront-ip-update.sh

AMAZON_IP_URL="https://ip-ranges.amazonaws.com/ip-ranges.json"
APACHE_CONF_IP="/etc/apache2/conf-available/amazon-cloudfront-ip.list"

set -e

TEMP_IP="$(mktemp)"
trap 'rm -f "$TEMP_IP"' EXIT HUP INT QUIT PIPE TERM

wget -q --tries=3 --timeout=10 -O- "$AMAZON_IP_URL" \
    | >"$TEMP_IP" jq -r '(.prefixes[] | select(.service == "CLOUDFRONT").ip_prefix),(.ipv6_prefixes[] | select(.service == "CLOUDFRONT").ipv6_prefix)'

# Check list
if [ ! -s "$TEMP_IP" ] || grep -v -x '[0-9a-f:.]\+/[0-9]\+' "$TEMP_IP"; then
    echo "Failed to download Amazon CloudFront IP ranges" 2>&1
    exit 1
fi

# Detect changes
if ! diff -q "$APACHE_CONF_IP" "$TEMP_IP"; then
    echo "Amazon CloudFront IP ranges have changed"
    # Activate it
    mv -f "$TEMP_IP" "$APACHE_CONF_IP"
    APACHE_SYNTAX_OK="$(/usr/sbin/apache2ctl configtest 2>&1)"
    if [ "$APACHE_SYNTAX_OK" == "Syntax OK" ]; then
        service apache2 reload >/dev/null
    else
        echo "ERROR: Amazon CloudFront IP change caused Apache syntax error: ${APACHE_SYNTAX_OK}" 1>&2
        exit 2
    fi
fi

exit 0
