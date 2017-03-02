#!/bin/bash
#
# Show web traffic of visitors from foreign countries.
#

LOG="/var/log/apache2/muforum-access.log"
EXCLUDES="HU,"

# Print "IP CC, COUNTRY" from IP address
Ip_country() {
    xargs -I % bash -c "echo -n '%'; geoiplookup -f /var/lib/geoip-database-contrib/GeoIP.dat '%' | cut -d ':' -f 2"
}

# List POST requests
#     Exclude countries
#     Get traffic of these visitors
#     Display in pager
grep -Fw POST "$LOG" | cut -d " " -f 1 \
    | sort -u | Ip_country | grep -v -E "$EXCLUDES" | cut -d " " -f 1 \
    | grep -Fw -f - "$LOG" \
    | less -S
