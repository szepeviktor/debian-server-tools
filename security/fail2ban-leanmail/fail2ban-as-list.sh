#!/bin/bash
#
# Test banned IP addresses.
#
# DEPENDS       :apt-get install geoipupdate mmdb-bin

# List TOP 10 AS-s
Top_10_AS()
{
    GEOIP2_AS="/var/lib/GeoIP/GeoLite2-ASN.mmdb"

    # shellcheck disable=SC2016
    zgrep -F -v '[recidive]' /var/log/fail2ban.log | sed -n -e 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | while read -r IP; do
            # sed expression for ONE lookup
            mmdblookup --file "$GEOIP2_AS" --ip "$IP" \
                | sed -n -e 's/^\s\+\(\([0-9]\+\)\|"\(.\+\)"\) <\S\+>$/\2\3/;TNext;x;/./{x;H;bNext};x;h;:Next;${x;s/\n/ /g;s/^/AS/;p}'
        done \
        | iconv -c -f LATIN2 -t UTF-8 \
        | sort | uniq -c \
        | sort -n -r | head
}

# List PTR-s of attackers from a specific AS
Hostname_AS()
{
    AS="$1"
    GEOIP2_AS="/var/lib/GeoIP/GeoLite2-ASN.mmdb"

    zgrep -F -v '[recidive]' /var/log/fail2ban.log | sed -n -e 's/^.* Ban \([0-9.]\+\)$/\1/p' \
        | sortip | uniq \
        | while read -r IP; do
            echo -n "$IP"
            # sed expression for ONE lookup
            mmdblookup --file "$GEOIP2_AS" --ip "$IP" autonomous_system_number \
                | sed -n -e 's/^\s\+\([0-9]\+\) <\S\+>$/ AS\1/p'
        done \
        | iconv -c -f LATIN2 -t UTF-8 \
        | grep -F -w "$AS" | cut -d " " -f 1 \
        | xargs -r -L 1 host -W 1 -t PTR
}

# List countries of unmatched attackers
Known_countries()
{
    GEOIP2_COUNTRY="/var/lib/GeoIP/GeoLite2-Country.mmdb"

    # shellcheck disable=SC2002
    cat /var/lib/courier/.cache/ip-reputation/known.list \
        | while read -r IP; do
            # sed expression for ONE lookup
            mmdblookup --file "$GEOIP2_COUNTRY" --ip "$IP" registered_country iso_code \
                | sed -n -e '0,/^\s*"\([A-Z]\+\)" <\S\+>$/s//\1/p'
        done \
        | sort | uniq -c
}
