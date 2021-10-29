#!/bin/bash
#
# Add all known NeverBounce probe servers to an ipset.
#

declare -a -r SUBDOMAINS=(
    "portal-%d.forcedzen.com."
    "tool-%d.scruffystoolbox.com."
    "node-%d.sourcexnet.com."
    "planet-%d.spaceisstupid.com."
    "portal-%d.typedefvoid.com."
    "node-%d.unsignedstatic.com."
)

Get_all_ips()
{
    for SUBDOMAIN in ${SUBDOMAINS[*]}; do
        for NUMBER in {1..10}; do
            # shellcheck disable=SC2059
            dig +short "$(printf "${SUBDOMAIN}" "${NUMBER}")"
        done
    done
}

ipset create neverbounce hash:net family inet hashsize 64 maxelem 256
ipset flush neverbounce

Get_all_ips | sortip -u | xargs -t -L 1 -- ipset add neverbounce
