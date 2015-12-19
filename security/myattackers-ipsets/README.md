# Dangerous IP ranges

Deny traffic from dangerous networks.

```bash
apt-get install -y ipset
head *.ipset | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
```

### ipset-persistent

http://sourceforge.net/projects/ipset-persistent/files/
