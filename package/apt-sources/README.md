# Providers' mirrors

- Packet:            http://mirror.ewr1.packet.net/debian
- Linode:            http://mirrors.linode.com/debian
- OVH:               http://debian.mirrors.ovh.net/debian
- server4you:        http://debian.intergenia.de/debian
- PCextreme:         http://debian.apt-get.eu/debian
- Steadfast:         http://mirror.steadfast.net/debian

### Debian mirrors

- Fastly/CloudFront: http://deb.debian.org/debian
- Closest mirror:    http://http.debian.net/debian
- National mirror:   http://ftp.COUNTRY-CODE.debian.org/debian

Fastest mirror

```bash
apt-get install netselect-apt
netselect-apt -c COUNTRY-CODE stable
```

### Get key ID and fingerprint from a URL

```bash
wget -qO- https://example.com/gpg.key | gpg - | sed -ne 's|^pub  \S\+/\(\S\+\) .*$|\1|p'
wget -qO- https://example.com/gpg.key | gpg --with-fingerprint --with-colons - | sed -ne 's|^fpr:::::::::\([0-9A-F]\+\):$|\1|p'
```

### Proposed updates

```
deb http://ftp.us.debian.org/debian stable-proposed-updates main contrib non-free
```

https://www.debian.org/releases/proposed-updates.html
