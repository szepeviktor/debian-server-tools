#!/bin/bash
#
# Don't send Fail2ban notification emails of IP-s with records
#
# VERSION       :0.2.7
# DATE          :2015-11-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host dos2unix grepcidr geoip-database-contrib
# CI            :shellcheck -e SC2059 leanmail.sh
# LOCATION      :/usr/local/sbin/leanmail.sh
# CRON-HOURLY   :CACHE_UPDATE="1" /usr/local/sbin/leanmail.sh 10.0.0.2

# Usage, remarks
#
# Replace sendmail in Fail2ban action
#     | /usr/local/sbin/leanmail.sh <ip> <sender> <dest>
#
# Serving a website over HTTPS reduces attacks!

# DNS blacklists

# https://www.projecthoneypot.org/httpbl_api.php
DNSBL1_HTTPBL_ACCESSKEY="hsffbftuslgh"
DNSBL1_HTTPBL="${DNSBL1_HTTPBL_ACCESSKEY}.%s.dnsbl.httpbl.org"
# Exploits Block List
# https://www.spamhaus.org/xbl/
DNSBL2_SPAMHAUS="%s.xbl.spamhaus.org"
# Private list of dangerous networks
# See: ${D}/mail/spammer.dnsbl/dangerous.dnsbl.zone
DNSBL3_DANGEROUS="%s.dangerous.dnsbl"
# https://www.torproject.org/projects/tordnsel.html.en
DNSBL4_TORDNSEL="%s.80.%s.ip-port.exitlist.torproject.org"
# XBL includes CBL (result: 127.0.0.2)
# http://www.abuseat.org/faq.html
#DNSBL5_ABUSEAT="%s.cbl.abuseat.org"

# HTTP API-s

# http://www.stopforumspam.com/usage
#HTTPAPI1_SFS="http://api.stopforumspam.org/api?ip=%s"
# https://cleantalk.org/wiki/doku.php
#HTTPAPI2_CT_AUTHKEY="*****"
#HTTPAPI2_CT="https://moderate.cleantalk.org/api2.0"
#HTTPAPI2_CT="https://api.cleantalk.org/?method_name=spam_check&auth_key=%s"
# https://www.dshield.org/api/
# handlers-a-t-isc.sans.edu
HTTPAPI3_DSHIELD="https://dshield.org/api/ip/%s"

# IP lists

# https://www.openbl.org/lists.html
LIST_OPENBL="https://www.openbl.org/lists/base.txt"
# http://cinsscore.com/#list
#LIST_CINSSCORE="http://cinsscore.com/list/ci-badguys.txt"
# https://greensnow.co/
# HTTP API: http://api.greensnow.co/
LIST_GREENSNOW="http://blocklist.greensnow.co/greensnow.txt"
# https://www.blocklist.de/en/export.html
LIST_BLDE="http://lists.blocklist.de/lists/all.txt"
LIST_BLDE_1H="https://api.blocklist.de/getlast.php?time=3600"

# https://ipsec.pl/files/ipsec/blacklist-ip.txt
#
# http://www.emergingthreats.net/open-source/etopen-ruleset
#NET_LIST_ET_RBN="http://doc.emergingthreats.net/pub/Main/RussianBusinessNetwork/RussianBusinessNetworkIPs.txt"
# https://www.threatstop.com/index.php?page=instructions&policy_id=1299&pg=iptables
# ftp://ftp.threatstop.com/pub/ts-iptables.tar.gz
#LIST_TS_BASIC="http://worker.szepe.net/ts/threatstop-basic.txt"
# http://www.spamhaus.org/drop/
#NET_LIST_SPAMHAUS_DROP="http://www.spamhaus.org/drop/drop.txt"
#NET_LIST_SPAMHAUS_EDROP="http://www.spamhaus.org/drop/edrop.txt"
# Its main purpose is to block SSH bruteforce attacks via firewall.
# http://danger.rulez.sk/index.php/bruteforceblocker/
#COMMENTED_LIST_DRSK_BFB="http://danger.rulez.sk/projects/bruteforceblocker/blist.php"
#LIST_ABUSE_FEODO="https://feodotracker.abuse.ch/blocklist/?download=ipblocklist"
#LIST_ABUSE_ZEUS="https://zeustracker.abuse.ch/blocklist.php?download=badips"

# Hosting only, no humans
declare -a AS_HOSTING=(
    AS14618 # Amazon.com, Inc.
    AS16509 # Amazon.com, Inc.
    AS16276 # OVH SAS
    AS18978 # Enzu Inc.
    AS12876 # ONLINE S.A.S.
    AS5577  # root SA
    AS36352 # ColoCrossing
    AS29073 # Ecatel LTD
    AS24940 # Hetzner Online GmbH
    AS8972  # PlusServer AG
)

# Labs
# wget -q -O- "http://api.abuseipdb.com/check/?ip=${IP}&cids=12,4,11,10,3,5,15,7,6,14,9,17,16,13&uid=${ABUSEIPDB_UID}&skey=${ABUSEIPDB_SKEY}&o=xml" \
#     | grep -q '<report cid="[0-9]\+" total="[0-9]\+" />'
# https://zeltser.com/malicious-ip-blocklists/
# http://www.umbradata.com/solutions
# # https://www.dshield.org/xml.html
# # https://www.dshield.org/hpbinfo.html
# # https://isc.sans.edu/diary/Reminder%3A+Proper+use+of+DShield+data/4483
# https://www.dshield.org/ipsascii.html?limit=5000
# https://www.cyveillance.com/home/security-solutions/data/


# Set CACHE_UPDATE global to "1" to allow list updates
#     CACHE_UPDATE="1" leanmail.sh 1.2.3.4

# Full IP match or first three octets only (Class C)
#CLASSC_MATCH="0"
CLASSC_MATCH="1"

# DNS resolver
#NS1="208.67.220.123" # OpenDNS
NS1="81.2.236.171" # worker

# Timeout in seconds
TIMEOUT="5"

# List cache path
CACHE_DIR="/var/lib/fail2ban"

# GeoIP database
COUNTRY_GEOIP="/usr/share/GeoIP/GeoIP.dat"
AS_GEOIP="/usr/share/GeoIP/GeoIPASNum.dat"

# Fail2ban action in sendmail-*.local
#     | /usr/local/sbin/leanmail.sh <ip> <sender> <dest>
IP="$1"
SENDER="$2"
DEST="$3"

Reverse_ip() {
    local STRING="$1"
    local REV

    REV="$(
        while read -r -d "." PART; do
            echo "$PART"
        done <<< "${STRING}." \
            | tac \
            | while read -r PART; do
                echo -n "${PART}."
            done
    )"

    echo "${REV%.}"
}

Log_match() {
    local MATCH="$1"

    logger -t "fail2ban-leanmail" "Banned IP (${IP}) matches ${MATCH}"
}

Get_cache_file() {
    local STRING="$1"
    local SHA

    SHA="$(echo -n "$STRING" | shasum -a 256 | cut -d " " -f 1)"

    echo "${CACHE_DIR}/${SHA}"
}

Update_cache() {
    local URL="$1"
    local CACHE_FILE
    local CACHE_FILE_TEMP

    CACHE_FILE="$(Get_cache_file "$URL")"
    CACHE_FILE_TEMP="$(mktemp "${CACHE_FILE}.XXXXXXXXXX")"

    # Long timeout, three tries
    wget -q -t 3 -O "$CACHE_FILE_TEMP" "$URL" 2> /dev/null

    # Circumvent the case of partially downloaded file
    if [ -s "$CACHE_FILE_TEMP" ]; then
        dos2unix --quiet "$CACHE_FILE_TEMP" 2> /dev/null
        mv -f "$CACHE_FILE_TEMP" "$CACHE_FILE"
    else
        rm -f "$CACHE_FILE_TEMP"
    fi
}

Match_list() {
    local LIST="$1"
    local IP="$2"
    local CACHE_FILE

    CACHE_FILE="$(Get_cache_file "$LIST")"

    if [ "$CACHE_UPDATE" == 1 ]; then
        Update_cache "$LIST"
    fi
    if ! [ -r "$CACHE_FILE" ]; then
        return 10
    fi

    if [ "$CLASSC_MATCH" == 0 ]; then
        # Full match
        grep -q -F -x "$IP" "$CACHE_FILE"
    else
        # 24 bit match
        grep -q -E -x "${IP%.*}\.[0-9]{1,3}" "$CACHE_FILE"
    fi
}

Match_commented_list() {
    local LIST="$1"
    local IP="$2"
    local CACHE_FILE

    CACHE_FILE="$(Get_cache_file "$LIST")"

    if [ "$CACHE_UPDATE" == 1 ]; then
        Update_cache "$LIST"
    fi
    if ! [ -r "$CACHE_FILE" ]; then
        return 10
    fi

    grepcidr -q -f "$CACHE_FILE" <<< "$IP"
}

Match_net_list() {
    local LIST="$1"
    local IP="$2"
    local CACHE_FILE

    CACHE_FILE="$(Get_cache_file "$LIST")"

    if [ "$CACHE_UPDATE" == 1 ]; then
        Update_cache "$LIST"
    fi
    if ! [ -r "$CACHE_FILE" ]; then
        return 10
    fi

    grepcidr -f "$CACHE_FILE" <<< "$IP" &> /dev/null
}

Match_dnsbl1() {
    local DNSBL="$1"
    local IP="$2"
    local ANSWER

    printf -v HOSTNAME "$DNSBL" "$(Reverse_ip "$IP")"

    ANSWER="$(host -W "$TIMEOUT" -t A "$HOSTNAME" "$NS1" 2> /dev/null | tail -n 1)"
    ANSWER="${ANSWER#* has address }"
    ANSWER="${ANSWER#* has IPv4 address }"

    if ! grep -q -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' <<< "$ANSWER"; then
        # NXDOMAIN, network error or invalid IP
        return 10
    fi

    # Fourth octet represents the type of visitor
    # 0 = Search Engine
    [ "${ANSWER##*.}" -gt 0 ]
}

Match_dnsbl2() {
    local DNSBL="$1"
    local IP="$2"
    local ANSWER

    printf -v HOSTNAME "$DNSBL" "$(Reverse_ip "$IP")"

    ANSWER="$(host -W "$TIMEOUT" -t A "$HOSTNAME" "$NS1" 2> /dev/null | tail -n 1)"
    ANSWER="${ANSWER#* has address }"
    ANSWER="${ANSWER#* has IPv4 address }"

    if ! grep -q -E -x '([0-9]{1,3}\.){3}[0-9]{1,3}' <<< "$ANSWER"; then
        # NXDOMAIN, network error or invalid IP
        return 10
    fi

    # Illegal 3rd party exploits, including proxies, worms and trojan exploits
    # 127.0.0.4-7
    grep -q -x "127.0.0.[4567]" <<< "$ANSWER"
}

Match_dnsbl3() {
    local DNSBL="$1"
    local IP="$2"
    local ANSWER

    printf -v HOSTNAME "$DNSBL" "$(Reverse_ip "$IP")"

    ANSWER="$(host -W "$TIMEOUT" -t A "$HOSTNAME" "$NS1" 2> /dev/null | tail -n 1)"
    ANSWER="${ANSWER#* has address }"
    ANSWER="${ANSWER#* has IPv4 address }"

    if ! grep -q -E -x '([0-9]{1,3}\.){3}[0-9]{1,3}' <<< "$ANSWER"; then
        # NXDOMAIN, network error or invalid IP
        return 10
    fi

    # 127.0.0.1   Dangerous network
    # 127.0.0.2   Tor exit node
    # 127.0.0.128 Blocked network
    grep -q -E -x "127.0.0.(1|2|128)" <<< "$ANSWER"
}

Match_dnsbl4() {
    local DNSBL="$1"
    local IP="$2"
    local OWN_IP
    local ANSWER

    OWN_IP="$(ip addr show dev eth0|sed -ne 's/^\s*inet \([0-9\.]\+\)\b.*$/\1/p')"
    printf -v HOSTNAME "$DNSBL" "$(Reverse_ip "$IP")" "$(Reverse_ip "$OWN_IP")"

    ANSWER="$(host -W "$TIMEOUT" -t A "$HOSTNAME" "$NS1" 2> /dev/null | tail -n 1)"
    ANSWER="${ANSWER#* has address }"
    ANSWER="${ANSWER#* has IPv4 address }"

    if ! grep -q -E -x '([0-9]{1,3}\.){3}[0-9]{1,3}' <<< "$ANSWER"; then
        # NXDOMAIN, network error or invalid IP
        return 10
    fi

    # Tor IP
    [ "$ANSWER" == 127.0.0.2 ]
}

Match_http_api1() {
    local HTTPAPI="$1"
    local IP="$2"
    local URL

    printf -v URL "$HTTPAPI" "$IP"
    if wget -q -T "$TIMEOUT" -t 1 -O- "$URL" 2> /dev/null | grep -q "<appears>yes</appears>"; then
        # IP is positive
        return 0
    fi

    return 10
}

Match_http_api2() {
    local HTTPAPI="$1"
    local IP="$2"
    local AUTHKEY="$3"
    local URL
    local POST

    printf -v URL "$HTTPAPI" "$IP"

    # https://cleantalk.org/wiki/doku.php?id=spam_check
    #curl -s "${HTTPAPI}" -d "data=${IP}"
    # == '{"data":{"'"$IP"'":{"appears":1}}}'

    printf -v POST '{"method_name":"check_newuser","auth_key":"%s","sender_email":"","sender_ip":"%s","js_on":1,"submit_time":15}' \
        "$AUTHKEY" "$IP"

    if wget -q -T "$TIMEOUT" -t 1 -O- --post-data="$POST" "$HTTPAPI" 2> /dev/null \
        | grep -q '"allow" : 0'; then
        # IP is positive
        return 0
    fi

    return 10
}

Match_http_api3() {
    local HTTPAPI="$1"
    local IP="$2"
    local URL

    printf -v URL "$HTTPAPI" "$IP"
    if wget -q -T "$TIMEOUT" -t 1 -O- "$URL" 2> /dev/null | grep -q "<attacks>[0-9]\+</attacks>"; then
        # IP is positive
        return 0
    fi

    return 10
}

Match_country() {
    local COUNTRY="$1"
    local IP="$2"

    if /usr/bin/geoiplookup -f "$COUNTRY_GEOIP" "$IP" | cut -d ":" -f 2- | grep -q "^ ${COUNTRY},"; then
        return 0
    fi

    return 10
}

Match_multi_AS() {
    local IP="$1"
    shift
    local -a AUTONOMOUS_SYSTEMS=( "$@" )
    local AS
    local IP_AS

    IP_AS="$(/usr/bin/geoiplookup -f "$AS_GEOIP" "$IP" | cut -d ":" -f 2-)"

    for AS in "${AUTONOMOUS_SYSTEMS[@]}"; do
        if grep -q "^ ${AS} " <<< "$IP_AS"; then
            return 0
        fi
    done

    return 10
}

Match_any() {
    # Local
    if Match_list "$LIST_BLDE" "$IP"; then
        Log_match "blde"
        return 0
    fi
    if Match_list "$LIST_GREENSNOW" "$IP"; then
        Log_match "greensnow"
        return 0
    fi
    if Match_list "$LIST_OPENBL" "$IP"; then
        Log_match "openbl"
        return 0
    fi
    if Match_country A1 "$IP"; then
        Log_match "anonymous-proxy"
        return 0
    fi
    if Match_multi_AS "$IP" "${AS_HOSTING[@]}"; then
        Log_match "hosting"
        return 0
    fi

    # Network
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        Log_match "spamhaus"
        return 0
    fi
    if Match_dnsbl3 "$DNSBL3_DANGEROUS" "$IP"; then
        Log_match "dangerous"
        return 0
    fi
    if Match_dnsbl4 "$DNSBL4_TORDNSEL" "$IP"; then
        Log_match "tordnsel"
        return 0
    fi
    if Match_http_api3 "$HTTPAPI3_DSHIELD" "$IP"; then
        Log_match "dshield"
        return 0
    fi

    # Labs :::::::::::::::::

    # Labs/network ::::::::::

    return 1
}

Match_all() {
    if Match_country A1 "$IP"; then
        echo "anonymous-proxy"
    fi
    if Match_multi_AS "$IP" "${AS_HOSTING[@]}"; then
        echo "hosting"
    fi
    if Match_list "$LIST_BLDE" "$IP"; then
        echo "blde"
    fi
    if Match_list "$LIST_BLDE_1H" "$IP"; then
        echo "blde-1h"
    fi
    if Match_list "$LIST_GREENSNOW" "$IP"; then
        echo "greensnow"
    fi
    if Match_list "$LIST_OPENBL" "$IP"; then
        echo "openbl"
    fi
    if Match_dnsbl3 "$DNSBL3_DANGEROUS" "$IP"; then
        echo "dangerous"
    fi
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        echo "spamhaus"
    fi
    if Match_dnsbl1 "$DNSBL1_HTTPBL" "$IP"; then
        echo "httpbl"
    fi
    if Match_dnsbl4 "$DNSBL4_TORDNSEL" "$IP"; then
        echo "tordnsel"
    fi
    if Match_http_api3 "$HTTPAPI3_DSHIELD" "$IP"; then
        echo "dshield"
    fi
    exit
}

[ -d "$CACHE_DIR" ] || exit 1

[ -z "$LEANMAIL_DEBUG" ] || CACHE_UPDATE="1" Match_all

if Match_any; then
    exit 0
fi

if [ "$IP" != 10.0.0.2 ]; then
# @TODO Report IP
# if sed '/\(bad_request_post_user_agent_empty\|no_wp_here_\)/{s//\1/;h};${x;/./{x;q0};x;q1}'; then
#     INSTANT_SECRET=""
#     wget -q -O- --post-data="auth=$(echo -n "${IP}${INSTANT_SECRET}"|shasum -a 256|cut -d" " -f1)&ip=${IP}" \
#         https://SITE/dnsbl.php &> /dev/null
# fi |
    /usr/sbin/sendmail -f "$SENDER" "$DEST"
fi
