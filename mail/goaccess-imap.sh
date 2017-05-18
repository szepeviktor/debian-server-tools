#!/bin/bash
#
# Real-time Courier IMAP login failure analyzer.
#
# VERSION       :0.1.1
# DEPENDS       :apt-get install goaccess

# Usage
#
#     ./goaccess-imap.sh [GOACCESS-OPTIONS]

Goaccess() {
    local GEOIP_DB="/var/lib/geoip-database-contrib/GeoLiteCityv6.dat"

    goaccess \
        --date-format="%b:%d" \
        --time-format="%T" \
        --log-format="%d %t %^ imapd-ssl: LOGIN FAILED, %u=%r, ip=[%h]" \
        --http-method=yes \
        --geoip-city-data="$GEOIP_DB" \
        --ignore-panel=REQUESTS_STATIC \
        --ignore-panel=NOT_FOUND \
        --ignore-panel=OS \
        --ignore-panel=BROWSERS \
        --ignore-panel=REFERRING_SITES \
        --ignore-panel=STATUS_CODES \
        --exclude-ip="$IP" \
        "$@"
}

# Own IP should be defined in .bashrc
if [ -z "$IP" ]; then
    exit 1
fi

# Get login failures, modify date
tail -n 1000000 -f /var/log/syslog \
    | grep -F "imapd-ssl: LOGIN FAILED," \
    | sed -e '/^\S\{1,5\}\s/s/ /:/' -e 's/^\(....\) /\10/' \
    | Goaccess "$@"
