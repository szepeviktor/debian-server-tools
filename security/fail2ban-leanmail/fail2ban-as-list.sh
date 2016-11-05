#!/bin/bash
#
# Test banned IP addresses.
#

# List TOP 10 AS-s
Top_10_AS() {
    AS_GEOIP="/usr/share/GeoIP/GeoIPASNum.dat"
    zgrep -Fv "[recidive]" /var/log/fail2ban.log | sed -ne 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | xargs -r -L1 geoiplookup -f ${AS_GEOIP} | recode -f l2..utf8 | cut -d: -f2- \
        | sort | uniq -c \
        | sort -n -r | head
}

# List PTR-s of attackers from a specific AS
Hostname_AS() {
    AS="$1"
    AS_GEOIP="/usr/share/GeoIP/GeoIPASNum.dat"
    zgrep -Fv "[recidive]" /var/log/fail2ban.log | sed -ne 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | xargs -I %% bash -c "echo -n %%;geoiplookup -f ${AS_GEOIP} %%|recode -f l2..utf8|cut -d: -f2-" \
        | grep -w "$AS" | cut -d' ' -f1 | xargs -r -L1 host -tA
}

# List country of unmatched attackers
Known_countries() {
    GEOIP="/usr/share/GeoIP/GeoIP.dat"
    cat /var/lib/fail2ban/known.list | xargs -n1 geoiplookup -f "$GEOIP" | sort | uniq -c
}
