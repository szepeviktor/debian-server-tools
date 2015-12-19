#!/bin/bash
#
# Display hits of ipsets and reset their counters.
#
# VERSION       :0.1.0
# LOCATION      :/usr/local/sbin/ipset-hits.sh

Reset_rule() {
    local IPSET="$1"
    local RULE
    local -i RULE_NUMBER

    RULE="$(iptables -n --line-numbers -L INPUT | grep -F "match-set ${IPSET} src reject-with icmp-port-unreachable")"
    RULE_NUMBER="${RULE%% *}"
    if [ -z "$RULE_NUMBER" ] || [ "$RULE_NUMBER" -lt 1 ]; then
        return 1
    fi

    iptables -vn -Z INPUT "$RULE_NUMBER" -L || echo "Error resetting rule for ${IPSET}" 1>&2
}

for IPSET in $(ipset list -name); do
    Reset_rule "$IPSET"
done
