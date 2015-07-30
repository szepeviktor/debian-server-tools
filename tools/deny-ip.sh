#!/bin/bash
#
# Ban an IP address on all or specified ports.
#
# VERSION       :0.1.1
# DATE          :2015-07-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/deny-ip.sh
# SYMLINK       :/usr/local/sbin/deny-http.sh
# SYMLINK       :/usr/local/sbin/deny-smtp.sh
# SYMLINK       :/usr/local/sbin/deny-ssh.sh

# List banned IP addresses without traffic
#
#     iptables --line-numbers -nvL MYATTACKERS | grep "^[0-9]\+\s\+0\s\+" | sort -n
#
# Delete all but the last ten rules
#
#     | tail -n +10 | cut -d" " -f1 | xargs -t -L1 iptables -D MYATTACKERS

SSH_PORT="22"

SOURCE="$1"

# Detect IPv4 address
isIP() {
    local TOBEIP="$1"
    #             0-9, 10-99, 100-199,  200-249,    250-255
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIP" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$ ]]
}

# Detect IPv4 address range
isIPrange() {
    local TOBEIPRANGE="$1"
    local MASKBITS="${TOBEIPRANGE##*/}"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIPRANGE" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}/[0-9]{1,2}$ ]] \
        && [ "$MASKBITS" -gt 0 ] && [ "$MASKBITS" -le 30 ]
}

# Validate IP address
if ! isIP "$SOURCE" && ! isIPrange "$SOURCE"; then
    echo "Usage: $0 IP-ADDRESS|IP-RANGE" >&2
    exit 1
fi

# Command name contains protocol
case "$(basename $0)" in
    deny-http.sh)
        PROTOCOL="-p tcp -m multiport --dports http,https"
        ;;
    deny-smtp.sh)
        PROTOCOL="-p tcp -m multiport --dports smtp,submission,smtps"
        ;;
    deny-ssh.sh)
        PROTOCOL="-p tcp --dport ${SSH_PORT}"
        ;;
    *)
        # By default ban all traffic
        PROTOCOL=""
        ;;
esac

iptables -n -L MYATTACKERS &> /dev/null \
    && iptables -I MYATTACKERS -s "$SOURCE" ${PROTOCOL} -j DROP \
    || echo "iptables chain error." >&2
