#!/bin/bash
#
# Deny traffic from dangerous networks.
#
# VERSION       :0.2.1
# DATE          :2016-04-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :*.ipset files

CHAIN="myattackers-ipset"

set -e

Add_ipsets() {
    head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash -x
}

Install_ipsets() {
    apt-get install -qq -y iptables-persistent ipset ipset-persistent

    iptables -N "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -A "$CHAIN" -j RETURN
    iptables -I INPUT -j "$CHAIN"

    if [ "$(lsb_release -sc)" == "wheezy" ]; then
        sed -i -e "s;^IPSET=;IPSET=$(which ipset);" /etc/init.d/ipset-persistent
    fi
    /etc/init.d/ipset-persistent save
}

Update_ipsets() {
    iptables -D INPUT -j "$CHAIN"
    iptables -F "$CHAIN"

    Add_ipsets
    ipset list -name

    iptables -A "$CHAIN" -j RETURN
    iptables -I INPUT -j "$CHAIN"

    /etc/init.d/ipset-persistent save
}

if iptables -C INPUT -j "$CHAIN" &> /dev/null; then
    Update_ipsets
else
    Install_ipsets
fi
