# Dangerous IP ranges

Deny traffic from dangerous networks.

```bash
apt-get install -y iptables-persistent ipset ipset-persistent
iptables -N myattackers-ipset
head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
iptables -A myattackers-ipset -j RETURN
iptables -I INPUT -j myattackers-ipset

ipset list
[ "$(lsb_release -sc)" == "wheezy" ] && sed -i -e "s;^IPSET=;IPSET=$(which ipset);" /etc/init.d/ipset-persistent
/etc/init.d/ipset-persistent save
```
