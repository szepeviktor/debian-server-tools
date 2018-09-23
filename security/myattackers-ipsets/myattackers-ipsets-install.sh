#!/bin/bash
#
# Deny traffic from hostile networks.
#
# VERSION       :0.7.1
# DATE          :2018-07-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :ipset/*.ipset

CHAIN="myattackers-ipset"

Add_ipsets()
{
    find ipset/ -type f -name "*.ipset" -print0 | sort -z -r \
        | xargs -r -0 \
            head | grep '^#: ip.\+' | cut -d " " -f 2- | /bin/bash -x
}

Install_ipsets()
{
    # @nonDebian
    apt-get install -y iptables-persistent ipset-persistent

    # Clear IP sets
    ipset destroy

    iptables -w -N "$CHAIN"
    Add_ipsets
    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -A INPUT -j "$CHAIN"

    ipset list -name

    if [ -x /etc/init.d/ipset-persistent ]; then
        if [ "$(lsb_release -s -c)" == wheezy ]; then
            sed -e "s#^IPSET=.*\$#IPSET=$(which ipset)#" -i /etc/init.d/ipset-persistent
        fi
        /etc/init.d/ipset-persistent save
    elif [ -x /usr/share/netfilter-persistent/plugins.d/10-ipset ]; then
        /usr/share/netfilter-persistent/plugins.d/10-ipset save
    fi
}

Update_ipsets()
{
    # Clear IP sets
    iptables -w -D INPUT -j "$CHAIN"
    iptables -w -F "$CHAIN"
    ipset destroy

    Add_ipsets
    iptables -w -A "$CHAIN" -j RETURN
    iptables -w -A INPUT -j "$CHAIN"

    ipset list -name

    if [ -x /etc/init.d/ipset-persistent ]; then
        /etc/init.d/ipset-persistent save
    elif [ -x /usr/share/netfilter-persistent/plugins.d/10-ipset ]; then
        /usr/share/netfilter-persistent/plugins.d/10-ipset save
    fi
}

set -e

test -d ipset

# Also checks chain existence
if iptables -w -C INPUT -j "$CHAIN" &>/dev/null; then
    Update_ipsets
else
    Install_ipsets
fi

# Save iptables chains and rules except Fail2ban rules
/sbin/iptables-save | grep -E -v '(:|\s)f2b-' >/etc/iptables/rules.v4
/sbin/ip6tables-save | grep -E -v '(:|\s)f2b-' >/etc/iptables/rules.v6
