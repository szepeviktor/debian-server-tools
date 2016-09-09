### Security audit

@TODO https://github.com/CISOfy/lynis/

### Malware analysis

https://www.payload-security.com/

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

### HTTP response security headers

https://securityheaders.io/

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

### CloudFlare IP ranges

- https://www.cloudflare.com/ips-v4
- https://www.cloudflare.com/ips-v6

### CloudFlare API v4 IP banning

mode: block | challenge | whitelist
target: country | ip

Value would be an IP, /16 /24 or a 2-letter country code.
The notes field can be left empty or removed if you don't want to add any.
To block for a specific zone only, just change the API URL to:

`https://api.cloudflare.com/client/v4/zones/YOUR-ZONE-ID/firewall/packages/access_rules/rules`

Replace YOUR-ZONE-ID with the zone identifier for the zone
retrieved via an API GET to `https://api.cloudflare.com/client/v4/zones/` with your API details.

```
curl --data-binary '{"mode":"block","notes":"","configuration":{"value":"1.2.3.4","target":"ip"}}' \
    --compressed -H 'Content-Type: application/json' \
    --header "X-Auth-Key: $API_KEY" --header "X-Auth-Email: $API_EMAIL" --verbose \
    'https://api.cloudflare.com/client/v4/user/firewall/packages/access_rules/rules'
```

### Incapsula IP ranges

https://incapsula.zendesk.com/hc/en-us/articles/200627570-Restricting-direct-access-to-your-website-Incapsula-s-IP-addresses-

resp_format: json | apache | nginx | iptables | text

```
curl -k -s --data 'resp_format=apache' 'https://my.incapsula.com/api/integration/v1/ips'
```

### Difference between “BEGIN RSA PRIVATE KEY” and “BEGIN PRIVATE KEY”

http://stackoverflow.com/questions/20065304/what-is-the-differences-between-begin-rsa-private-key-and-begin-private-key/20065522#20065522

### OpenVPN in Linux console

```
sudo openvpn --ca /abs/path/unsigned-ca.crt --config /abs/path/config.ovpn --auth-user-pass /abs/path/userpass --daemon
```
