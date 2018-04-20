#!/bin/bash
#
# Update Cloudflare IPv4 list for mod_remoteip.
#
# VERSION       :0.2.1
# DATE          :2016-12-31
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# REFS          :/etc/apache2/mods-available/remoteip.conf
# DEPENDS       :apt-get install apache2
# LOCATION      :/usr/local/sbin/cloudflare-ipv4-update.sh
# CRON-DAILY    :/usr/local/sbin/cloudflare-ipv4-update.sh

CLOUDFLARE_IPV4_URL="https://www.cloudflare.com/ips-v4"
APACHE_CONF_IPV4="/etc/apache2/conf-available/cloudflare-ipv4.list"

set -e

TEMP_IPV4="$(mktemp)"
trap 'rm -f "$TEMP_IPV4"' EXIT HUP INT QUIT PIPE TERM

wget -q --tries=3 --timeout=10 -O "$TEMP_IPV4" "$CLOUDFLARE_IPV4_URL"

# Check list
if [ ! -s "$TEMP_IPV4" ] || grep -v -x '[0-9.]\+/[0-9]\+' "$TEMP_IPV4"; then
    echo "Failed to download CloudFlare IPv4 list" 2>&1
    exit 1
fi

# Detect changes
if ! diff -q "$APACHE_CONF_IPV4" "$TEMP_IPV4"; then
    echo "Cloudflare IPv4 ranges have changed"
    # Activate it
    mv -f "$TEMP_IPV4" "$APACHE_CONF_IPV4"
    APACHE_SYNTAX_OK="$(/usr/sbin/apache2ctl configtest 2>&1)"
    if [ "$APACHE_SYNTAX_OK" == "Syntax OK" ]; then
        service apache2 reload > /dev/null
    else
        echo "ERROR: Cloudflare IPv4 change caused Apache syntax error: ${APACHE_SYNTAX_OK}" 1>&2
        exit 2
    fi
fi

exit 0
