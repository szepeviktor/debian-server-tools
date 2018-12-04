#!/bin/bash

WP_URL="http://shifty.uk.plesk-server.com/wordpress/"
WP_IP="109.109.132.250"

# WordPress core 4.2
#
# Plugins
#
# - https://github.com/szepeviktor/sucuri-cleanup/archive/master.zip
# - sucuri-scanner
# - wp-mailfrom-ii
#
# Theme: twentyfifteen

[ -x /usr/bin/time ] || exit 99

export LC_NUMERIC=C

UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:40.0) Gecko/20100101 Firefox/40.0"

Avg()
{
    local MUL="$1"

    echo "( $(paste -d "+" -s) ) * ${MUL} / 1" | bc
}

Ping()
{
    printf '%s        (ms) ' "$WP_IP"

    # Precharge routers
    ping -c 1 "$WP_IP" &>/dev/null

    # ms * 5 * 0.2
    for _ in {1..5}; do
        ping -c 1 "$WP_IP" | sed -n -e 's/^.* time=\([[:digit:]]\+\).* ms$/\1/p' || exit 1
    done \
        | Avg 0.2
}

Http() {
    echo -n "${WP_URL} (ms) "

    # Precharge DNS and PHP opcode cache
    wget -q -O /dev/null "$WP_URL"

    # s * 5 * 200
    for _ in {1..5}; do
        /usr/bin/time --format "%e" wget -q -O /dev/null --user-agent="$UA" "$WP_URL" 2>&1 || exit 2
    done \
        | Avg 200
}

Http
Ping
echo "PHP process time = ( HTTP - Ping )"
