# Custom DNS blacklist and whitelist

## The stack

- alias interface
- rbldns
- unbound
- spamassassin

### Alias interface

unbound needs an IP address different from localhost.
Append the content of `interfaces` to `/etc/network/interfaces`.

### rbldns

Copy `rbldnsd` to `/etc/default/`
and `known-hosts.dnsbl.zone` and `spammer.dnsbl.zone` to /var/lib/rbldns/spammer/
Rootdir hardcoded: `/var/lib/rbldns/spammer`

### Unbound

Copy `known-hosts.conf` and `spammer.conf` to `/etc/unbound/unbound.conf.d/`.

### Spamassassin

Copy `20_known-hosts.dnsbl.cf` and `20_spammer.dnsbl.cf` to `/etc/spamassassin/`.

## Pseudo script

All these in commands.

```bash
exit 0 # do not execute it, use copy&paste

# on the DNS server
apt-get install -y rbldnsd unbound
cat interfaces >> /etc/network/interfaces
ifup eth0:1
mkdir -p /var/lib/rbldns/spammer
cp -vf known-hosts.dnsbl.zone /var/lib/rbldns/spammer/
cp -vf spammer.dnsbl.zone /var/lib/rbldns/spammer/
cp -vf rbldnsd /etc/default/
service rbldnsd restart
cp -vf known-hosts.conf /etc/unbound/unbound.conf.d/
cp -vf spammer.conf /etc/unbound/unbound.conf.d/
service unbound restart

# on the clients
cp -vf 20_known-hosts.dnsbl.cf /etc/spamassassin/
cp -vf 20_spammer.dnsbl.cf /etc/spamassassin/
sudo -u daemon -- spamassassin --lint && service spamassassin restart
```
