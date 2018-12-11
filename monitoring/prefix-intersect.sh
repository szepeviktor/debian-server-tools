#!/bin/bash
#
# Test overlapping IPv4 prefixes.
#
# DEPENDS       :apt-get install sipcalc

# Prefix list file from https://bgp.he.net/AS1#_prefixes
PREFIX_LIST="$1"

Ip2dec()
{
    local IPV4="$1"
    local -i OCTET1 OCTET2 OCTET3 OCTET4

    IFS="." read -r OCTET1 OCTET2 OCTET3 OCTET4 <<<"$IPV4"
    echo "$(( (OCTET1 << 24) + (OCTET2 << 16) + (OCTET3 << 8) + OCTET4 ))"
}

declare -a PREFIXES PREFIXES_FROM PREFIXES_TO
declare -i FROM TO FROM2 TO2 INTERSECTIONS

set -e

test -r "$PREFIX_LIST"

INTERSECTIONS="0"

# Parse prefix list file
while read -r PREFIX; do
    test -z "$PREFIX" && continue
    test "${PREFIX:0:3}" == ROA && continue
    test "${PREFIX:0:3}" == IRR && continue

    PREFIXES+=( "$PREFIX" )
    FROM_TO="$(sipcalc "$PREFIX" | sed -n -e 's|^Network range\s\+- \([0-9.]\+\) - \([0-9.]\+\)$|\1:\2|p')"
    PREFIXES_FROM+=( "$(Ip2dec "${FROM_TO%:*}")" )
    PREFIXES_TO+=( "$(Ip2dec "${FROM_TO#*:}")" )
done <"$PREFIX_LIST"

# Loop through prefixes
declare -i TOTAL="${#PREFIXES[*]}"
for NUMBER in $(seq 0 "$((TOTAL - 2))"); do
    echo "Testing #${NUMBER} ${PREFIXES[$NUMBER]} ..." 1>&2
    FROM="${PREFIXES_FROM[$NUMBER]}"
    TO="${PREFIXES_TO[$NUMBER]}"

    # Compare to other prefixes
    for NUMBER2 in $(seq "$((NUMBER + 1))" "$((TOTAL - 1))"); do
        # DBG echo "  Comparing to #${NUMBER2} ${PREFIXES[$NUMBER2]} ..."
        FROM2="${PREFIXES_FROM[$NUMBER2]}"
        TO2="${PREFIXES_TO[$NUMBER2]}"

        #   1..1
        # 2......2
        if [[ "$FROM2" -lt "$FROM" && "$TO2" -gt "$TO" ]]; then
            INTERSECTIONS+="1"
            echo "${PREFIXES[$NUMBER2]} covers ${PREFIXES[$NUMBER]}"
            continue
        fi

        # 1.....1
        #    2.....2
        if [[ "$FROM2" -ge "$FROM" && "$FROM2" -le "$TO" ]]; then
            INTERSECTIONS+="1"
            echo "${PREFIXES[$NUMBER2]} starts within ${PREFIXES[$NUMBER]}"
            continue
        fi

        #    1.....1
        # 2.....2
        if [[ "$TO2" -ge "$FROM" && "$TO2" -le "$TO" ]]; then
            INTERSECTIONS+="1"
            echo "${PREFIXES[$NUMBER2]} ends within ${PREFIXES[$NUMBER]}"
            continue
        fi
    done
done

echo "Number of intersections: ${INTERSECTIONS}" 1>&2
