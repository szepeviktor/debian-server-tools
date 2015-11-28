# Dangerous IP ranges

Deny traffic from a network:

```bash
cat NETNAME.ipset | head | grep "^#: ip.\+" | cut -d " " -f 2- | /bin/bash
```

### ipset-persistent

http://sourceforge.net/projects/ipset-persistent/files/
