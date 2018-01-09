#!/bin/bash
#
# Show web traffic of visitors from foreign countries.
#

LOG="/var/log/apache2/muforum-access.log"
EXCLUDES="(HU|DE)"

# Print "IP CC, COUNTRY" from IP address
Ip_country() {
    xargs -I % bash -c "echo -n '% '; mmdblookup --file /var/lib/GeoIP/GeoLite2-Country.mmdb --ip '%' registered_country iso_code | sed -n -e '0,/.*\"\([A-Z]\+\)\".*/s//\1/p'"
}

# List POST requests
#     Exclude countries
#     Get traffic of these visitors
#     Display in pager
grep -Fw POST "$LOG" | cut -d " " -f 1 \
    | sort -u | Ip_country | grep -v -E " ${EXCLUDES}\$" | cut -d " " -f 1 \
    | grep -F -w -f - "$LOG" \
    | less -S
