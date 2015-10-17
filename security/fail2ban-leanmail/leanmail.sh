#!/bin/bash
#
# Don't send Fail2ban notification emails of IP-s with records
#
# VERSION       :0.1.1
# DATE          :2015-10-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host
# LOCATION      :/usr/local/sbin/leanmail.sh
# CRON-HOURLY   :CACHE_UPDATE="1" /usr/local/sbin/leanmail.sh 127.0.0.2

# Usage, remarks
#
# Replace sendmail in Fail2ban action
#     | /usr/local/sbin/leanmail.sh <ip> <sender> <dest>
#
# Serving a website over HTTPS reduces attacks!

# DNS blacklists

# Private list of dangerous networks
DNSBL1_DANGEROUS="%s.dangerous.dnsbl"
# https://www.projecthoneypot.org/httpbl_api.php
DNSBL1_HTTPBL="hsffbftuslgh.%s.dnsbl.httpbl.org"
# https://www.spamhaus.org/xbl/
DNSBL2_SPAMHAUS="%s.xbl.spamhaus.org"
# XBL includes CBL
# # http://www.abuseat.org/faq.html
# DNSBL3_ABUSEAT="%s.cbl.abuseat.org"

# HTTP API-s

#http://www.stopforumspam.com/usage
HTTPAPI1_SFS="http://api.stopforumspam.org/api?ip=%s"

# IP lists

# https://www.openbl.org/lists.html
LIST_OPENBL="https://www.openbl.org/lists/base.txt"
# http://cinsscore.com/#list
LIST_CINSSCORE="http://cinsscore.com/list/ci-badguys.txt"
# https://greensnow.co/
LIST_GREENSNOW="http://blocklist.greensnow.co/greensnow.txt"
# https://www.blocklist.de/en/export.html
LIST_BLDE="http://lists.blocklist.de/lists/all.txt"
LIST_BLDE_1H="https://api.blocklist.de/getlast.php?time=3600"

# Set CACHE_UPDATE global to "1" to allow list updates
#     CACHE_UPDATE="1" leanmail.sh 127.0.0.2

# Full IP match or first three octets only (Class C)
#CLASSC_MATCH="0"
CLASSC_MATCH="1"

# DNS resolver
#NS1="208.67.220.123" # OpenDNS
NS1="81.2.236.171" # worker.szepe.net

# Timeout in seconds
TIMEOUT="5"

# List cache path
CACHE_DIR="/var/lib/fail2ban"

# Fail2ban action in sendmail-*.local
#     | /usr/local/sbin/leanmail.sh <ip> <sender> <dest>
IP="$1"
SENDER="$2"
DEST="$3"

Reverse_ip() {
    local STRING="$1"
    local REV

    REV="$(
        while read -d "." PART; do
            echo "$PART"
        done <<< "${STRING}." \
            | tac \
            | while read PART; do
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

    CACHE_FILE="$(Get_cache_file "$URL")"

    wget -T "$TIMEOUT" --quiet -O "$CACHE_FILE" "$URL" 2> /dev/null
}

Match_list() {
    local LIST="$1"
    local IP="$2"
    local CACHE_FILE

    CACHE_FILE="$(Get_cache_file "$LIST")"

    if ! [ -r "$CACHE_FILE" ]; then
        if [ "$CACHE_UPDATE" == 1 ]; then
            Update_cache "$LIST"
        fi
        return 10
    fi

    if [ "$CLASSC_MATCH" == 0 ]; then
        # Full match
        grep -q -F -x "$IP" "$CACHE_FILE"
    else
        # 24 bit match
        grep -q -E "^${IP%.*}\.[0-9]{1,3}$" "$CACHE_FILE"
    fi
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
    if [ "${ANSWER##*.}" -gt 0 ]; then
        # IP is positive
        return 0
    else
        return 1
    fi
}

Match_dnsbl2() {
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

    # Illegal 3rd party exploits, including proxies, worms and trojan exploits
    # 127.0.0.4-7
    grep -q "^127.0.0.[4567]$" <<< "$ANSWER"
}

Match_http_api1() {
    local HTTPAPI="$1"
    local IP="$2"
    local URL

    printf -v URL "$HTTPAPI" "$IP"
    if wget -T "$TIMEOUT" --quiet -O- "$URL" 2> /dev/null | grep -q "<appears>yes</appears>"; then
        # IP is positive
        return 0
    fi

    return 10
}

Match_any() {
    # Local
    if Match_list "$LIST_OPENBL" "$IP"; then
        Log_match "openbl"
        return 0
    fi
    if Match_list "$LIST_CINSSCORE" "$IP"; then
        Log_match "cinsscore"
        return 0
    fi
    if Match_list "$LIST_GREENSNOW" "$IP"; then
        Log_match "greensnow"
        return 0
    fi
    if Match_list "$LIST_BLDE" "$IP"; then
        Log_match "blde"
        return 0
    fi
    if Match_list "$LIST_BLDE_1H" "$IP"; then
        Log_match "blde1h"
        return 0
    fi

    # DNS
    if Match_dnsbl1 "$DNSBL1_DANGEROUS" "$IP"; then
        Log_match "dangerous"
        return 0
    fi
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        Log_match "spamhaus"
        return 0
    fi
    if Match_dnsbl1 "$DNSBL1_HTTPBL" "$IP"; then
        Log_match "httpbl"
        return 0
    fi

    # HTTP
    if Match_http_api1 "$HTTPAPI1_SFS" "$IP"; then
        Log_match "sfs"
        return 0
    fi

    return 1
}

Match_all() {
    if Match_list "$LIST_BLDE_1H" "$IP"; then
        echo "blde1h"
    fi
    if Match_list "$LIST_BLDE" "$IP"; then
        echo "blde"
    fi
    if Match_list "$LIST_GREENSNOW" "$IP"; then
        echo "greensnow"
    fi
    if Match_list "$LIST_OPENBL" "$IP"; then
        echo "openbl"
    fi
    if Match_list "$LIST_CINSSCORE" "$IP"; then
        echo "cinsscore"
    fi
    if Match_dnsbl1 "$DNSBL1_DANGEROUS" "$IP"; then
        echo "dangerous"
    fi
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        echo "spamhaus"
    fi
    if Match_dnsbl1 "$DNSBL1_HTTPBL" "$IP"; then
        echo "httpbl"
    fi
    if Match_http_api1 "$HTTPAPI1_SFS" "$IP"; then
        echo "sfs"
    fi
    exit
}

[ -d "$CACHE_DIR" ] || exit 1

[ -z "$LEANMAIL_DEBUG" ] || CACHE_UPDATE="1" Match_all

if Match_any; then
    exit 0
fi

/usr/sbin/sendmail -f "$SENDER" "$DEST"
