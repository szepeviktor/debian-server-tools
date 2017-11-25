#!/bin/bash
#
# Deny traffic from hostile networks.
#
# VERSION       :0.4.1
# DATE          :2017-10-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :ipset/*.ipset

CHAIN="myattackers-ipset"

Add_ipsets() {
    find ipset/ -type f -name "*.ipset" -print0 | sort -z -r | xargs -r -0 \
        head | grep '^#: ip.\+' | cut -d " " -f 2- | /bin/bash -x
}

Install_ipsets() {
    # @nonDebian
    apt-get install -y iptables-persistent ipset-persistent

    iptables -w -N "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -I INPUT -j "$CHAIN"

    if [ -x /etc/init.d/ipset-persistent ]; then
        if [ "$(lsb_release -s -c)" == "wheezy" ]; then
            sed -i -e "s;^IPSET=;IPSET=$(which ipset);" /etc/init.d/ipset-persistent
        fi
        /etc/init.d/ipset-persistent save
    elif [ -x /usr/share/netfilter-persistent/plugins.d/10-ipset ]; then
        /usr/share/netfilter-persistent/plugins.d/10-ipset save
    fi
}

Update_ipsets() {
    iptables -w -D INPUT -j "$CHAIN"
    iptables -w -F "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -I INPUT -j "$CHAIN"

    if [ -x /etc/init.d/ipset-persistent ]; then
        /etc/init.d/ipset-persistent save
    elif [ -x /usr/share/netfilter-persistent/plugins.d/10-ipset ]; then
        /usr/share/netfilter-persistent/plugins.d/10-ipset save
    fi
}

set -e

if iptables -w -C INPUT -j "$CHAIN" &> /dev/null; then
    Update_ipsets
else
    Install_ipsets
fi

cat << "EOF"
iptables-save | grep -E -v '(:|\s)f2b-' | sed -e 's| \[[0-9]*:[0-9]*\]$| [0:0]|' > /etc/iptables/rules.v4
EOF
