#!/bin/bash


Reset_rule() {
    local IPSET="$1"
    local -i RULE_NUMBER

    get rule number || 

    iptables -vn -Z INPUT "$RULE_NUMBER" -L || echo "Error resetting rule #${RULE_NUMBER}" 1>&2
}

for IPSET in ecatel hostkey; do
    Reset_rule "$IPSET"
done
