#!/bin/bash
#
# Test banned IP addresses.
#

# List TOP 10 AS-s
Top_10_AS() {
    GEOIP2_AS="/var/lib/GeoIP/GeoLite2-ASN.mmdb"

    # shellcheck disable=SC2016
    zgrep -Fv "[recidive]" /var/log/fail2ban.log | sed -ne 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | while read -r IP; do
            # sed expression if for ONE lookup
            mmdblookup --file "$GEOIP2_AS" --ip "$IP" \
            | sed -n -e 's/^\s\+\(\([0-9]\+\)\|"\(.\+\)"\) <\S\+>$/\2\3/;TNext;x;/./{x;H;bNext};x;h;:Next;${x;s/\n/ /g;s/^/AS/;p}'
        done \
        | iconv -c -f LATIN2 -t UTF-8 \
        | sort | uniq -c \
        | sort -n -r | head
}

# List PTR-s of attackers from a specific AS
Hostname_AS() {
    AS="$1"
    GEOIP2_AS="/var/lib/GeoIP/GeoLite2-ASN.mmdb"
    GEOIP2_DATA="autonomous_system_number"

    zgrep -Fv "[recidive]" /var/log/fail2ban.log | sed -ne 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | xargs -r -I% bash -c "echo -n %;mmdblookup --file '$GEOIP2_AS' --ip % '$GEOIP2_DATA'|sed -ne 's/^\\s\\+\\([0-9]\\+\\) <\\S\\+>\$/ AS\\1/p'|iconv -c -fLATIN2 -tUTF-8" \
        | grep -F -w "$AS" | cut -d" " -f1 \
        | xargs -r -L 1 host -W 1 -t PTR
}

# List countries of unmatched attackers
Known_countries() {
    GEOIP2_COUNTRY="/var/lib/GeoIP/GeoLite2-Country.mmdb"

    # shellcheck disable=SC2002
    cat /var/lib/fail2ban/known.list \
        | xargs -r -I% bash -c "mmdblookup --file '$GEOIP2_COUNTRY' --ip % registered_country iso_code|sed -ne '0,/^\\s*\"\\([A-Z]\\+\\)\" <\\S\\+>\$/s//\\1/p'" \
        | sort | uniq -c
}
