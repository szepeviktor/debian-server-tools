#!/bin/bash
#
# Show web traffic of visitors from abroad.
#

LOG="/var/log/apache2/project-access.log"
EXCLUDES="(HU|DE)"

# Print "IP CC, COUNTRY" from IP address
Ip_country()
{
    local GEOIP="/var/lib/GeoIP/GeoLite2-Country.mmdb"
    local IP

    while read -r IP; do
        printf '%s ' "$IP"
        mmdblookup --file "$GEOIP" --ip "$IP" registered_country iso_code \
            | sed -n -e '0,/.*"\([A-Z]\+\)".*/s//\1/p'
    done
}

# List POST requests
#     Exclude countries
#     Get traffic of these visitors
#     Display in pager
grep -F -w 'POST' "$LOG" | cut -d " " -f 1 \
    | sort -u | Ip_country | grep -v -E " ${EXCLUDES}\$" | cut -d " " -f 1 \
    | grep -F -w -f - "$LOG" \
    | less -S
