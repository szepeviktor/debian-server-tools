# Dangerous IP ranges

Deny traffic from dangerous networks.

```bash
apt-get install -y ipset
head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
ipset list
[ -x /etc/init.d/ipset-persistent save ] && /etc/init.d/ipset-persistent save
```

### ipset-persistent

http://sourceforge.net/projects/ipset-persistent/files/
