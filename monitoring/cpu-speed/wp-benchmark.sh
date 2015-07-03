#!/bin/bash

WP_URL="https://esküvői-videók.hu/"
WP_IP="79.172.214.123"

WP_URL="http://degeneralt.hu/"
WP_IP="81.2.236.108"

WP_URL="http://szepe.hol.es/1w/"
WP_IP="31.220.16.217"

WP_URL="http://www.lean-hr.hu/"
WP_IP="95.140.33.67"

WP_URL="https://maxer.hu/"
WP_IP="178.238.210.115"

WP_URL="http://ssdtarhely.eu/"
WP_IP="80.249.160.195"

WP_URL="http://http2.olm.hu/wp2/"
WP_IP="108.61.176.53"

WP_URL="http://szepe.byethost13.com/"
WP_IP="185.27.134.200"

WP_URL="http://bf.szepe.net/bf/"
WP_IP="185.11.145.5"

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

Avg() {
    MUL="$1"
    echo "( $(paste -d"+" -s) ) * $MUL / 1" | bc
}

Ping() {
    echo -n "${WP_IP}        (ms) "

    # Precharge routers
    ping -c 1 "$WP_IP" &> /dev/null

    # ms * 5 * 0.2
    for i in $(seq 1 5); do
        ping -c 1 "$WP_IP" | sed -n 's/^.* time=\([[:digit:]]\+\).* ms$/\1/p' || exit 1
    done \
        | Avg 0.2
}

Http() {
    echo -n "${WP_URL} (ms) "

    # Precharge DNS and PHP opcode cache
    wget -q -O /dev/null "$WP_URL"

    # s * 5 * 200
    for i in $(seq 1 5); do
        /usr/bin/time --format "%e" wget -q -O /dev/null --user-agent="$UA" "$WP_URL" 2>&1 || exit 2
    done \
        | Avg 200
}

Http
Ping
echo "PHP process time = ( HTTP - Ping )"
