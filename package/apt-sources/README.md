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
- National mirror:   `http://ftp.COUNTRY-CODE.debian.org/debian`

Fastest mirror

```bash
apt-get install netselect-apt
netselect-apt -c COUNTRY-CODE stable
```

### Get key ID/fingerprint

```bash
wget -qO- $KEY_URL | gpg - | sed -ne 's|^pub\s\+\S\+/\(\S\+\) .*$|\1|p'
wget -qO- $KEY_URL | gpg --with-fingerprint --with-colons - | sed -ne 's|^fpr:::::::::\([0-9A-F]\+\):$|\1|p'

apt-key adv --fingerprint $KEY_ID | sed -ne 's|^pub\s\+\S\+/\(\S\+\) .*$|\1|p'
apt-key adv --fingerprint --with-colons $KEY_ID | sed -ne 's|^fpr:::::::::\([0-9A-F]\+\):$|\1|p'
```

### OpenPGP keyservers

https://sks-keyservers.net/status/

Suggested servers: `ha.pool.sks-keyservers.net`

### Proposed updates

```
deb http://ftp.us.debian.org/debian stable-proposed-updates main contrib non-free
```

https://www.debian.org/releases/proposed-updates.html
