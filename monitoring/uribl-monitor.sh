#!/bin/bash
#
# Monitor uribl's server for unbound usage.
#

# editor /etc/unbound/unbound.conf.d/uribl.conf

# http://uribl.com/mirrors.shtml
URIBL_HOST="ff.uribl.com."
NEAREST_IP="54.72.143.21"

Error()
{
    echo "ERROR: $*" | mail -s "uribl.com failure" admin@szepe.net
    exit 1
}

declare -i LOOPS="2"

# IP address
host -t A "$URIBL_HOST" 2>&1 | grep -q -x "${URIBL_HOST%.} has \\(IPv4 \\)\\?address ${NEAREST_IP}" \
    || Error "IP address of ${URIBL_HOST} has changed"

# Test response
while [ "$LOOPS" -gt 0 ]; do
    LOOPS+="-1"
    # OK
    if host -t A 2.0.0.127.multi.uribl.com. "$NEAREST_IP" 2>&1 \
        | grep -q -x '2\.0\.0\.127\.multi\.uribl\.com has \(IPv4 \)\?address 127\.0\.0\.14'; then
        exit 0
    fi
    sleep 60
done

# Not OK
Error "Invalid test response from uribl.com"
