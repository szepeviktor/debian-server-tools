#!/bin/bash
#
# Measure HTTPS response time.
#
# VERSION       :0.2.3
# DATE          :2016-11-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install time openssl
# LOCATION      :/usr/local/bin/https-get-time.sh

# Usage
#     https-time.sh https://example.com/page

# Use -S option after the URL to show HTTP response headers and body on stdout.

# User-Agent
UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20130809 Firefox/47.0"

IsIP()
{
    local TOBEIP="$1"

    grep -q -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' <<<"$TOBEIP"
}

Hide()
{
    if [ "$SHOW" == "-S" ]; then
        cat
    else
        cat >/dev/null
    fi
}

set -e

URL="$1"
SHOW="$2"

# Empty URL
test -n "$URL"
# No http:// URLs
test -z "${URL##https*}"

# Parse host name
HOST="$(sed -e 's|^\([^/]*//\)\?\([^:/]\+\).*$|\2|' <<< "$URL")"
test -n "$HOST"
( ! IsIP "$HOST" )

# Parse request path
REQ="${URL##*$HOST}"
if [ -z "$REQ" ]; then
    REQ="/"
fi

IP="$(host -t A "$HOST")"
# FIXME First IP only
test "$IP" != "${IP##* has address }"
IP="${IP##* has address }"
test -n "$IP"

# Send request and return wall clock time in seconds,
# optionally show full response.
{
    cat <<EOF
GET ${REQ} HTTP/1.1
Host: ${HOST}
User-Agent: ${UA}
Accept: text/html
Accept-Language: en
Connection: close

EOF
    sleep 5
} | sed -e 's/$/\r/' \
    | /usr/bin/time --format "%e" openssl s_client -connect "${IP}:443" -servername "$HOST" -crlf | Hide
