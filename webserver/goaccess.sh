#!/bin/bash
#
# Real-time web log analyzer.
#
# VERSION       :0.2.3
# DEPENDS       :apt-get install goaccess sipcalc jq

# Usage
#
# Rebuild goaccess with #define MAX_IGNORE_IPS 1024 in src/settings.h
#
#     ./goaccess.sh [GOACCESS-OPTIONS]

U="$(stat . -c %U)"
#U="${1:-defaultuser}"
HTTPS="ssl-"
#HTTPS=""
EXCLUDES="amazon_cloudfront hetrixtools webymon szepenet"
#EXCLUDES="amazon_cloudfront pingdom cloudflare hetrixtools webymon szepenet custom"

# https://myip.ms/info/bots/Google_Bing_Yahoo_Facebook_etc_Bot_IP_Addresses.html
Exclude_custom() {
    local IPLIST
    local CUSTOM_HOST="example.com"

    if ! Exclude_enabled custom; then
        return
    fi

    IPLIST="$(host -t A "$CUSTOM_HOST" | cut -d " " -f 4)"

    echo "$IPLIST" | Make_excludes
}

Exclude_szepenet() {
    local IPLIST

    if ! Exclude_enabled szepenet; then
        return
    fi

    #       worker       proxy
    IPLIST="81.2.236.171,88.151.99.143"

    echo "$IPLIST" | tr ',' '\n' | Make_excludes
}

Get_cache_file() {
    local URL="$1"
    local CACHE_HOME
    local URL_SHA
    local CACHE_FILE
    local TIMESTAMP_FILE

    # Cache dir
    if [ -d "$XDG_CACHE_HOME" ]; then
        CACHE_HOME="$XDG_CACHE_HOME"
    else
        CACHE_HOME="${HOME}/.cache"
    fi
    if [ ! -d "${CACHE_HOME}/goaccess" ]; then
        mkdir -p "${CACHE_HOME}/goaccess"
    fi

    URL_SHA="$(echo -n "$URL" | shasum -a 256 | cut -d " " -f 1)"
    CACHE_FILE="${CACHE_HOME}/goaccess/${URL_SHA}"
    TIMESTAMP_FILE="${CACHE_HOME}/goaccess/${URL_SHA}.timestamp"

    if [ -f "$CACHE_FILE" ] && [ -f "$TIMESTAMP_FILE" ]; then
        if [ "$(cat "$TIMESTAMP_FILE")" -lt "$(date -d "1 day ago" "+%s")" ]; then
            # Exists & Expired -> download
            rm "$CACHE_FILE" "$TIMESTAMP_FILE"
        fi
    fi

    # Does not exist -> download
    if [ ! -f "$CACHE_FILE" ] || [ ! -f "$TIMESTAMP_FILE" ]; then
        wget -t 1 -q -O "$CACHE_FILE" "$URL"
        date "+%s" > "$TIMESTAMP_FILE"
    fi

    echo "$CACHE_FILE"
}

Exclude_enabled() {
    local NAME="$1"
    local PADDED_EXCLUDES=" ${EXCLUDES} "

    test "${PADDED_EXCLUDES/ ${NAME} /}" != "$PADDED_EXCLUDES"
}

Make_excludes() {
    # shellcheck disable=SC2016
    xargs -n 1 bash -c 'echo -n " --exclude-ip=$0"'
}

Exclude_cloudflare() {
    local IPLIST

    if ! Exclude_enabled cloudflare; then
        return
    fi

    IPLIST="$(Get_cache_file "https://www.cloudflare.com/ips-v4")"

    < "$IPLIST" xargs -n 1 sipcalc | sed -n -e 's|^Network range\s\+- \(.\+\) - \(.\+\)$|\1-\2|p' \
        | Make_excludes
}

Exclude_pingdom() {
    local IPLIST

    if ! Exclude_enabled pingdom; then
        return
    fi

    IPLIST="$(Get_cache_file "https://my.pingdom.com/probes/ipv4")"

    < "$IPLIST" Make_excludes
}

Exclude_amazon_cloudfront() {
    local IPLIST

    if ! Exclude_enabled amazon_cloudfront; then
        return
    fi

    IPLIST="$(Get_cache_file "https://ip-ranges.amazonaws.com/ip-ranges.json")"

    < "$IPLIST" jq -r ".prefixes[].ip_prefix" \
        | xargs -n 1 sipcalc | sed -n -e 's|^Network range\s\+- \(.\+\) - \(.\+\)$|\1-\2|p' \
        | Make_excludes
}

Exclude_hetrixtools() {
    local IPLIST

    if ! Exclude_enabled hetrixtools; then
        return
    fi

    IPLIST="$(Get_cache_file "https://hetrixtools.com/resources/uptime-monitor-ips.txt")"

    < "$IPLIST" sed -n -e 's|^\S\+\s\([0-9.]\+\)$|\1|p' \
        | Make_excludes
}

Exclude_webymon() {
    local IPLIST

    if ! Exclude_enabled webymon; then
        return
    fi

    #IPLIST="$(for N in {01..10}; do host -t A crawler-node-${N}.webymon.com.; done | sed -n -e 's/^.* has address \([0-9.]\+\)$/\1/p' | uniq)"
    IPLIST="138.201.159.186 88.99.187.152 88.99.187.153 91.120.24.189"

    echo "$IPLIST" | Make_excludes
}

Goaccess() {
    local GEOIP_DB="/var/lib/geoip-database-contrib/GeoLiteCity.dat"

    # shellcheck disable=SC2046
    goaccess \
        --ignore-crawlers \
        --agent-list \
        --http-method=yes \
        --all-static-files \
        --geoip-city-data="$GEOIP_DB" \
        --log-format='%h %^[%d:%t %^] "%r" %s %b "%R" "%u"' \
        --date-format="%d/%b/%Y" \
        --time-format="%T" \
        $(Exclude_amazon_cloudfront) \
        $(Exclude_pingdom) \
        $(Exclude_cloudflare) \
        $(Exclude_hetrixtools) \
        $(Exclude_webymon) \
        $(Exclude_szepenet) \
        $(Exclude_custom) \
        --exclude-ip="$IP" \
        "$@"
}

# Own IP should be defined in .bashrc
if [ -z "$IP" ]; then
    exit 1
fi

Goaccess -f "/var/log/apache2/${U}-${HTTPS}access.log" "$@"

# List log files by size
#     ls -lSr /var/log/apache2/*access.log

# Multiple log files (not real time)
#cat /var/log/apache2/${U}-{ssl-,}access.log | Goaccess "$@"

# HTML output
#Goaccess -f "/var/log/apache2/${U}-${HTTPS}access.log" "$@" > "/home/${U}/website/html/stat.html"

# HTML output from multiple log files
#( zcat /var/log/apache2/${U}-{ssl-,}access.log.{3,2}.gz
#  cat /var/log/apache2/${U}-{ssl-,}access.log{1,} ) | Goaccess "$@" > "/home/${U}/website/html/stat.html"
