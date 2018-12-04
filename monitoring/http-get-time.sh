#!/bin/bash
#
# Measure HTTP response time.
#
# VERSION       :0.3.0
# DATE          :2016-11-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install netcat-openbsd moreutils
# LOCATION      :/usr/local/bin/http-get-time.sh

# Usage
#
#     http-time.sh http://example.com/page | sed -e 's|\s| |g' | cut -c 1-${COLUMNS}


# User-Agent
UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20130809 Firefox/47.0"

IsIP()
{
    local TOBEIP="$1"

    grep -q '^\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}$' <<<"$TOBEIP"
}

set -e

URL="$1"

# Empty URL
test -n "$URL"
# No https:// URLs
test -n "${URL##https*}"

# Parse host name
HOST="$(sed -e 's#^\([^/]*//\)\?\([^:/]\+\).*$#\2#' <<<"$URL")"
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

# Send request and display timestamped response
{
    cat <<EOF
GET ${REQ} HTTP/1.1
Host: ${HOST}
User-Agent: ${UA}
Accept: text/html
Accept-Language: en
Connection: close

EOF
} | sed -e 's/$/\r/' | nc "$IP" 80 | ts -s "%.s"
