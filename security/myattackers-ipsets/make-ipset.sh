#!/bin/bash
#
# Create an ipset file from an rbldnsd list.
#

# Example input file
#
#     mirtelematiki
#     # AS49335 - Mir Telematiki Ltd.
#     141.105.64.0/21 RU_HOSTKEY@Mir Telematiki/AS49335
#     158.255.0.0/21  RU_HOSTKEY@Mir Telematiki/AS49335

# 1st line
read -r NAME
# 2nd line
read -r ASLINE

{
    cat <<EOF
# ${ASLINE### }
#: ipset -exist restore <ipset/${NAME}.ipset
#: iptables -w -I myattackers-ipset -m set --match-set ${NAME} src -j REJECT
create ${NAME} hash:net family inet hashsize 64 maxelem 32
flush ${NAME}
EOF

    # Following lines
    while read -r IPRANGE; do
        echo "add ${NAME} ${IPRANGE%% *}"
    done
} >"${NAME}.ipset"
