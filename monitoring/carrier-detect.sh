#!/bin/bash
#
# List all carriers.
#

Set_iana_special() {
    # uses global $IPV4_SPECIAL

    # https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
    IPV4_SPECIAL=(
        0.
        10.
        127.
        169.254.
        192.0.0.
        192.0.2.
        192.31.196.
        192.52.193.
        192.88.99.
        192.168.
        192.175.48.
        198.51.100.
        203.0.113.
        255.255.255.255
    )

    # 100.64.0.0/10
    # 172.16.0.0/12
    # 198.18.0.0/15
    # 240.0.0.0/4
    for I in {64..127}; do IPV4_SPECIAL+=( 100.${I}. ); done
    for I in {16..31}; do IPV4_SPECIAL+=( 172.${I}. ); done
    for I in {18..19}; do IPV4_SPECIAL+=( 198.${I}. ); done
    for I in {240..255}; do IPV4_SPECIAL+=( ${I}. ); done

    # Skip multicast addresses too
    for I in {224..239}; do IPV4_SPECIAL+=( ${I}. ); done
}

Match_special() {
    # uses global $IPV4_SPECIAL
    local IP="$1"
    local SP

    for SP in "${IPV4_SPECIAL[@]}"; do
        SP="${SP//./\\.}"
        if [[ "$IP" =~ ^${SP} ]]; then
            return 0
        fi
    done

    return 1
}

Get_addresses() {
    local A
    local B
    local C
    local D
    local IP

    # Whole IPv4 address space
    for A in {0..255}; do
        # Four addresses, one in each 64 segment
        for B in 1 65 129 193; do
            # Random third and fourth octet
            C="$((RANDOM % 256))"
            D="$((RANDOM % 254 + 1))"

            IP="${A}.${B}.${C}.${D}"
            if Match_special "$IP"; then
                continue
            fi

            # Return the address
            echo "$IP"
        done
    done
}

declare -a IPV4_SPECIAL

set -e

Set_iana_special

for IP in $(Get_addresses); do
    echo "${IP} ..." 1>&2

    HOP="$(traceroute -n -4 -w 1 -f 2 -m 2 "$IP" | sed -n -e '$s|^ 2  \([0-9.]\+\) .*$|\1|p')"
    # Detect UpCloud/Frankfurt routers
    if [[ "$HOP" =~ ^94\.237\.(24|25|26|27|28|29|30|31)\. ]]; then
        echo "Third hop ..." 1>&2
        traceroute -n -4 -w 1 -f 3 -m 3 "$IP" | sed -n -e '$s|^ 3  \([0-9.]\+\) .*$|\1|p'
    elif [ -n "$HOP" ]; then
        echo "$HOP"
    fi
done
