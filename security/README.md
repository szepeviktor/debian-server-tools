### Custom certificate installation

/usr/local/share/ca-certificates/<CA-NAME>/

### Store secret data in shares

#### gfshare

`apt-get install -y libgfshare-bin`
http://www.digital-scurf.org/software/libgfshare

### Cipher names correspondence table @Mozilla

[Cipher names correspondence table](https://wiki.mozilla.org/Security/Server_Side_TLS#Cipher_names_correspondence_table)

[TLS Names table generator](https://github.com/jvehent/tlsnames)

### Detect supported SSL ciphersuites

```bash
nmap --script ssl-cert,ssl-enum-ciphers -p 443 <TARGET>
```

### DigiCert (online)

[DigiCert® SSL Installation Diagnostics Tool](https://www.digicert.com/help/)

### Qualys SSL Labs (online)

[SSL Server Test](https://www.ssllabs.com/ssltest/index.html)

### OWASP Testing Guide

[Testing for Weak SSL/TLS Ciphers, Insufficient Transport Layer Protection](https://www.owasp.org/index.php/Testing_for_Weak_SSL/TLS_Ciphers,_Insufficient_Transport_Layer_Protection_(OTG-CRYPST-001))

### SSLyze

[SSLyze, Fast and full-featured SSL scanner](https://github.com/nabla-c0d3/sslyze)

### cipherscan

[cipherscan](https://github.com/jvehent/cipherscan) also analyzes configurations

### SSL Breacher

[SSL Breacher - Yet Another SSL Test Tool](http://bl0g.yehg.net/2014/07/ssl-breacher-yet-another-ssl-test-tool.html)

## Settings

### Cipherli.st

[Strong Ciphers for Apache, nginx and Lighttpd](https://cipherli.st/)

### Mozilla Server side TLS Tools

[Server side TLS Tools](http://mozilla.github.io/server-side-tls/ssl-config-generator/),
doc: [Server Side TLS Document](https://wiki.mozilla.org/Security/Server_Side_TLS)

## hosts.deny

### China

```
# ASIA/China
sshd: 27.0.0.0/8
sshd: 58.0.0.0/8
sshd: 59.0.0.0/8
sshd: 60.0.0.0/8
sshd: 61.0.0.0/8
sshd: 110.0.0.0/8
sshd: 111.0.0.0/8
sshd: 112.0.0.0/8
sshd: 113.0.0.0/8
sshd: 114.0.0.0/8
sshd: 115.0.0.0/8
sshd: 116.0.0.0/8
sshd: 117.0.0.0/8
sshd: 118.0.0.0/8
sshd: 119.0.0.0/8
sshd: 120.0.0.0/8
sshd: 121.0.0.0/8
sshd: 122.0.0.0/8
sshd: 123.0.0.0/8
sshd: 124.0.0.0/8
sshd: 125.0.0.0/8
sshd: 183.0.0.0/8
sshd: 210.0.0.0/8
sshd: 211.0.0.0/8
sshd: 218.0.0.0/8
sshd: 219.0.0.0/8
sshd: 220.0.0.0/8
sshd: 221.0.0.0/8
sshd: 222.0.0.0/8
sshd: 223.0.0.0/8
```

### CloudFlare IP ranges

- https://www.cloudflare.com/ips-v4
- https://www.cloudflare.com/ips-v6

### CloudFlare IP banning

mode:   block / challenge / whitelist
target: country / ip
Value would be an IP, /16 /24 or a 2-letter country code.
The notes field can be left empty or removed if you don't want to add any.
To block for a specific zone only, just change the API URL to:
`https://api.cloudflare.com/client/v4/zones/YOUR-ZONE-ID/firewall/packages/access_rules/rules`
Replace YOUR-ZONE-ID with the zone identifier for the zone
retrieved via an API GET to `https://api.cloudflare.com/client/v4/zones/` with your API details.

```
curl 'https://api.cloudflare.com/client/v4/user/firewall/packages/access_rules/rules' \
    --data-binary '{"mode":"block","notes":"","configuration":{"value":"1.2.3.4","target":"ip"}}' \
    --compressed -H 'content-type: application/json' \
    --header "X-Auth-Key: YOUR-API-KEY" --header "X-Auth-Email: YOUR-EMAIL-ADDRESS" --verbose
```

### Incapsula IP ranges

https://incapsula.zendesk.com/hc/en-us/articles/200627570-Restricting-direct-access-to-your-website-Incapsula-s-IP-addresses-

resp_format: json | apache | nginx | iptables | text
`curl -k -s --data "resp_format=apache" https://my.incapsula.com/api/integration/v1/ips`
