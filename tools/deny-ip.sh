#!/bin/bash
#
# Ban an IP address on all or specified ports.
#
# VERSION       :0.1
# DATE          :2015-01-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/deny-ip.sh
# SYMLINK       :ln -vs /usr/local/sbin/deny-ip.sh /usr/local/sbin/deny-http.sh
# SYMLINK       :ln -vs /usr/local/sbin/deny-ip.sh /usr/local/sbin/deny-smtp.sh
# SYMLINK       :ln -vs /usr/local/sbin/deny-ip.sh /usr/local/sbin/deny-ssh.sh


# detect IPv4 address
isIP() {
    local TOBEIP="$1"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIP" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$ ]]
}

# detect IPv4 address ranges
isIPrange() {
    local TOBEIPRANGE="$1"
    local MASKBITS="${TOBEIPRANGE##*/}"
    local OCTET="([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"

    [[ "$TOBEIPRANGE" =~ ^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}/[0-9]{1,2}$ ]] \
        && [ "$MASKBITS" -gt 0 ] && [ "$MASKBITS" -le 30 ]
}

SOURCE="$1"
PROTOCOL=""
SSH_PORT="22"

# validate
if ! isIP "$SOURCE" && ! isIPrange "$SOURCE"; then
    echo "Usage: $0 <IP-ADDRESS>|<IP-RANGE>" >&2
    exit 1
fi

# executed command name tells what port to block
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
esac

iptables -n -L MYATTACKERS &> /dev/null \
    && iptables -I MYATTACKERS -s "$SOURCE" ${PROTOCOL} -j DROP \
    || echo "iptables error" >&2
