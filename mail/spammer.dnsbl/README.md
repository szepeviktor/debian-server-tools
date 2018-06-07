# Custom DNS blacklist and whitelist

## The stack

- alias network interface `eth0:1`
- rbldnsd
- unbound
- spamassassin

### Alias interface

Unbound needs an IP address different from localhost.
Append the content of `interfaces` to `/etc/network/interfaces`.

### rbldns

Copy `rbldnsd` to `/etc/default/`
and `spammer.dnsbl.zone` to /var/lib/rbldns/spammer/
Rootdir hardcoded: `/var/lib/rbldns/spammer`

### Unbound

Copy `spammer.conf` to `/etc/unbound/unbound.conf.d/`.

### Spamassassin

Copy `20_spammer_dnsbl.cf` to `/etc/spamassassin/`.

## Pseudo script

All the above in commands.

```bash
# Do not execute it, use copy&paste
exit 0

# On the DNS server
apt-get install -y rbldnsd unbound
cat interfaces >> /etc/network/interfaces
ifup eth0:1
mkdir -p /var/lib/rbldns/spammer
cp -vf spammer.dnsbl.zone /var/lib/rbldns/spammer/
cp -vf rbldnsd /etc/default/
service rbldnsd restart
cp -vf spammer.conf /etc/unbound/unbound.conf.d/
service unbound restart

# On the clients
cp -vf 20_spammer_dnsbl.cf /etc/spamassassin/
editor /etc/spamassassin/local.cf
#     dns_server  IP-ADDRESS
sudo -u courier -- spamassassin --lint && service spamassassin restart
```
