#!/bin/bash
#
# Deny traffic from dangerous networks.
#
# VERSION       :0.2.3
# DATE          :2016-04-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :ipset/*.ipset

CHAIN="myattackers-ipset"

set -e

Add_ipsets() {
    head ipset/*.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash -x
}

Install_ipsets() {
    # @nonDebian
    apt-get install -y iptables-persistent ipset ipset-persistent

    iptables -w -N "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -I INPUT -j "$CHAIN"

    if [ "$(lsb_release -s -c)" == "wheezy" ]; then
        sed -i -e "s;^IPSET=;IPSET=$(which ipset);" /etc/init.d/ipset-persistent
    fi
    /etc/init.d/ipset-persistent save
}

Update_ipsets() {
    iptables -w -D INPUT -j "$CHAIN"
    iptables -w -F "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -I INPUT -j "$CHAIN"

    /etc/init.d/ipset-persistent save
}

if iptables -w -C INPUT -j "$CHAIN" &> /dev/null; then
    Update_ipsets
else
    Install_ipsets
fi
