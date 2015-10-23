#!/bin/bash
#
# Don't send Fail2ban notification emails of IP-s with records
#
# VERSION       :0.1.4
# DATE          :2015-10-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install bind9-host
# LOCATION      :/usr/local/sbin/leanmail.sh
# CRON-HOURLY   :CACHE_UPDATE="1" /usr/local/sbin/leanmail.sh 10.0.0.2

# Usage, remarks
#
# Replace sendmail in Fail2ban action
#     | /usr/local/sbin/leanmail.sh <ip> <sender> <dest>
#
# Serving a website over HTTPS reduces attacks!

# DNS blacklists

# Private list of dangerous networks
# See: ${D}/mail/spammer.dnsbl/dangerous.dnsbl.zone
DNSBL1_DANGEROUS="%s.dangerous.dnsbl"
# https://www.projecthoneypot.org/httpbl_api.php
DNSBL1_HTTPBL_ACCESSKEY="hsffbftuslgh"
DNSBL1_HTTPBL="%s.%s.dnsbl.httpbl.org"
# https://www.spamhaus.org/xbl/
DNSBL2_SPAMHAUS="%s.xbl.spamhaus.org"
# XBL includes CBL
# # http://www.abuseat.org/faq.html
# DNSBL3_ABUSEAT="%s.cbl.abuseat.org"

# HTTP API-s

# http://www.stopforumspam.com/usage
HTTPAPI1_SFS="http://api.stopforumspam.org/api?ip=%s"
# https://cleantalk.org/wiki/doku.php
HTTPAPI2_CT_AUTHKEY="*****"
HTTPAPI2_CT="https://moderate.cleantalk.org/api2.0"
#HTTPAPI2_CT="https://api.cleantalk.org/?method_name=spam_check&auth_key=%s"

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
#     CACHE_UPDATE="1" leanmail.sh 1.2.3.4

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
    local CACHE_FILE_TEMP

    CACHE_FILE="$(Get_cache_file "$URL")"
    CACHE_FILE_TEMP="${CACHE_FILE}.tmp"

    wget -T "$TIMEOUT" --quiet -O "$CACHE_FILE_TEMP" "$URL" 2> /dev/null
    # Circumvent partially downloaded file
    if [ -f "$CACHE_FILE_TEMP" ; then
        mv -f "$CACHE_FILE_TEMP" "$CACHE_FILE"
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
        grep -q -E "^${IP%.*}\.[0-9]{1,3}$" "$CACHE_FILE"
    fi
}

Match_dnsbl1() {
    local DNSBL="$1"
    local IP="$2"
    local ACCESSKEY="$3"
    local ANSWER

    printf -v HOSTNAME "$DNSBL" "$ACCESSKEY" "$(Reverse_ip "$IP")"

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

    if ! grep -q -E -x '([0-9]{1,3}\.){3}[0-9]{1,3}' <<< "$ANSWER"; then
        # NXDOMAIN, network error or invalid IP
        return 10
    fi

    # Illegal 3rd party exploits, including proxies, worms and trojan exploits
    # 127.0.0.4-7
    grep -q -x "127.0.0.[4567]" <<< "$ANSWER"
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

    if wget -T "$TIMEOUT" --quiet -O- --post-data="$POST" "$HTTPAPI" 2> /dev/null \
        | grep -q '"allow" : 0'; then
        # IP is positive
        return 0
    fi

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

    # DNS
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        Log_match "spamhaus"
        return 0
    fi
    if Match_dnsbl1 "$DNSBL1_DANGEROUS" "$IP"; then
        Log_match "dangerous"
        return 0
    fi

    # HTTP

    return 1
}

Match_all() {
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
    if Match_list "$LIST_CINSSCORE" "$IP"; then
        echo "cinsscore"
    fi
    if Match_dnsbl1 "$DNSBL1_DANGEROUS" "$IP"; then
        echo "dangerous"
    fi
    if Match_dnsbl2 "$DNSBL2_SPAMHAUS" "$IP"; then
        echo "spamhaus"
    fi
    if Match_dnsbl1 "$DNSBL1_HTTPBL" "$IP" "$DNSBL1_HTTPBL_ACCESSKEY"; then
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

# @TODO Report IP to: ??? custom.php?

if [ "$IP" != 10.0.0.2 ]; then
    /usr/sbin/sendmail -f "$SENDER" "$DEST"
fi
