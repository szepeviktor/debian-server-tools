# ipset-persistent - Boot-time loader for ipset rules

### TODO

Make it a `netfilter-persistent` plugin as /usr/share/netfilter-persistent/plugins.d/14-ipset

### How to Build

```bash
apt-get install -y devscripts
dpkg-buildpackage -uc -us
```

### Compatibility

Compatible with `netfilter-persistent` package.

### Links

- [iptables-persistent source](http://anonscm.debian.org/cgit/collab-maint/iptables-persistent.git/tree/)
- [Debian bug: iptables-persistent: support ipset](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=693177)
- [Ununtu bug: iptables-persistent lacks support for ipset](https://bugs.launchpad.net/ubuntu/+source/iptables-persistent/+bug/1405670)
- Alternative: https://github.com/soar/ipset-persistent/blob/master/etc/init.d/ipset-persistent
