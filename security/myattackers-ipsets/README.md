# Dangerous IP ranges

Deny traffic from a network:

```bash
apt-get install -y ipset
head NETNAME.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
```

### ipset-persistent

http://sourceforge.net/projects/ipset-persistent/files/
