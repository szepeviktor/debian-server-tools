#!/bin/bash
#
# Measures HTTP response time and show it on stderr
# Use -S option to show HTTP response on stdout
#
# VERSION       :0.2
# DATE          :2014-08-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/ncget-time.sh
# DEPENDS       :apt-get install netcat-traditional


# User-Agent
UA="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:20.3) Gecko/20130809 Firefox/20.3 PaleMoon/20.3-x64"

URL="$1"
SHOW="$2"

isIP() {
    local TOBEIP="$1"

    if grep -q "^\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}\$" <<<"$TOBEIP"; then
        return 0
    else
        return 1
    fi
}

hide() {
    if [ "$SHOW" = "-S" ]; then
        cat
    else
        cat > /dev/null
    fi
}

# empty URL
[ -z "$URL" ] && exit 1
# no https:// URLs
[ -z "${URL##https*}" ] && exit 2

# parse host name
HOST="$(sed -e "s|\([^/]*\/\/\\)\?\([^:/]*\).*|\2|" <<< "$URL")"  #"
[ -z "$HOST" ] && exit 3


# parse request path
REQ="${URL##*$HOST}"
[ -z "$REQ" ] && REQ="/"

# get host's IP
if isIP "$HOST"; then
    IP="$HOST"
else
    IP="$(host -t A "$HOST")"
    [ "$IP" = ${IP##* has address } ] && exit 4
    IP="${IP##* has address }"
    [ -z "$IP" ] && exit 5
fi

# DBG
#echo "HOST: $HOST, PATH: $REQ"

# send request, return wall clock time in seconds
# optionally show full response
echo \
"GET ${REQ} HTTP/1.1
Host: ${HOST}
User-Agent: ${UA}
Accept: text/html
Accept-Language: en
Connection: close

" | /usr/bin/time --format "%e" nc "$IP" 80 | hide

