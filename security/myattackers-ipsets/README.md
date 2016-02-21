# Dangerous IP ranges

Deny traffic from dangerous networks.

```bash
apt-get install -y iptables-persistent ipset ipset-persistent
head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
ipset list
[ "$(lsb_release -sc)" == "wheezy" ] && sed -i -e "s;^IPSET=;IPSET=$(which ipset);" /etc/init.d/ipset-persistent
/etc/init.d/ipset-persistent save
```
