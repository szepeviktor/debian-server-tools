#!/bin/bash
#
# List all IPv4 carriers.
#
# VERSION       :0.3.0
# DATE          :2018-12-08
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+

# Usage
#     ./carrier-detect.sh >ipv4
#     cat ipv4 | sort -n | uniq -c

# EDIT here
ROUTER_EXP='^94\.237\.(0|80)\.'

Set_iana_special()
{
    # global $IPV4_SPECIAL

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
    for I in 100.{64..127}.; do IPV4_SPECIAL+=( "$I" ); done
    for I in 172.{16..31}.; do IPV4_SPECIAL+=( "$I" ); done
    for I in 198.{18..19}.; do IPV4_SPECIAL+=( "$I" ); done
    for I in {240..255}.; do IPV4_SPECIAL+=( "$I" ); done

    # Skip multicast addresses too
    for I in {224..239}.; do IPV4_SPECIAL+=( "$I" ); done
}

Match_special()
{
    # global $IPV4_SPECIAL
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

Get_addresses()
{
    local A
    local B
    local C
    local D
    local IP

    # Whole IPv4 address space
    for A in {0..255}; do
        # Four addresses, one in each 64 segment
        for B in 1 65 129 193; do
        #for B in $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)); do
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

Get_hop()
{
    local DEST="$1"
    local -i NUMBER="$2"

    traceroute -n -4 -w 2 -f "$NUMBER" -m "$NUMBER" "$DEST" | sed -n -e "\$s/^ ${NUMBER}  \\([0-9.]\\+\\) .*\$/\\1/p"
}

declare -a IPV4_SPECIAL
declare -a ORDINALS=( "0" "1" "Second" "Third" "Fourth" "Fifth" "Sixth" "Seventh" "Eighth" "Ninth" )

set -e

GREEN_CHECKMARK="$(tput setaf 2)✓$(tput sgr0)"

Set_iana_special

for IP in $(Get_addresses); do
    # Inspect second hop through ninth
    for NUMBER in {2..9}; do
        printf '%-16s  %s hop is ' "${IP}:" "${ORDINALS[$NUMBER]}" 1>&2
        HOP="$(Get_hop "$IP" "$NUMBER")"

        # Failure
        if [ -z "$HOP" ]; then
            echo "not available." 1>&2
            break
        fi

        # Detect local routers
        if [[ "$HOP" =~ ${ROUTER_EXP} ]]; then
            echo "local." 1>&2
            if [ "$NUMBER" -ge 6 ]; then
                echo "××××× [CRITICAL] Possible routing problem!" 1>&2
            fi
            continue
        fi

        # Found carrier
        echo "${HOP} ${GREEN_CHECKMARK}" 1>&2
        echo "$HOP"
        break
    done
done
