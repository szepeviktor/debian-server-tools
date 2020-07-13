### Account compromised in a data breach

- https://hacked-emails.com/
- `https://hacked-emails.com/api?q=user@example.com`
- https://haveibeenpwned.com/
- `https://haveibeenpwned.com/api/v2/breachedaccount/user@example.com`
- https://breachalarm.com/
- https://sec.hpi.uni-potsdam.de/ilc/search

### Incident (abuse) reporting

https://www.csirt.cz/reportingrules/ and https://aws.amazon.com/forms/report-abuse

> Subject should contain the **IP address** and **case type**
> - Sending email spam
> - Spamming online forums or other websites
> - Hosting a site advertised in spam
> - Excessive web crawling
> - Intrusion attempts (ssh, FTP, etc)
> - Exploit attacks (SQL injections, remote file inclusions, etc)
> - Hosting unlicensed copyright-protected material
> - Phishing website
> - Pharming website
> - Website hosting viruses/malware
> - Credit card fraud
> - Open proxy
> - Port scanning
> - IRC botnet activity
> - Denial of Serice attack (DoS/DDoS)
> - Alleged misuse of copyrighted work

Details

- URL
- Source and destination IP addresses
- Source and destination ports
- Time zone

### Security audit

@TODO https://github.com/CISOfy/lynis/

### HTTP CSP - Content Security Policy

- https://securityheaders.io/
- https://report-uri.io/
- https://report-uri.io/home/generate

### Malware analysis

https://www.hybrid-analysis.com/ malware analysis (file upload) by [Payload Security](https://www.payload-security.com/)

### Shared server server-wide security

Proactive

- mod_security
- [WAF for WordPress](https://github.com/szepeviktor/waf4wordpress)
- File modification monitoring + reverting from snapshot
- [ConfigServer Security & Firewall (csf)](https://configserver.com/cp/csf.html)
- HTTP authentication
- Honeypots [Nofollow Robot Trap](https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/mu-nofollow-robot-trap)
- https://bitninja.io/modules/
- http://nintechnet.com/ninjafirewall/ (for applications only)

Post incident

- [ConfigServer eXploit Scanner (cxs)](https://configserver.com/cp/cxs.html) $$$
- [SecuriteInfo Clamav signatures](https://www.securiteinfo.com/services/anti-spam-anti-virus/improve-detection-rate-of-zero-day-malwares-for-clamav.shtml)
- [VirusTotal](https://www.virustotal.com/) API (checksum of changed files)
- [VxStream Sandbox](https://www.hybrid-analysis.com/) API (checksum of changed files)

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

### Mozilla (online)

[Observatory](https://observatory.mozilla.org/)

### Cryptosense

https://discovery.cryptosense.com/

### Qualys SSL Labs (online)

[SSL Server Test](https://www.ssllabs.com/ssltest/index.html)

### DigiCert (online)

[DigiCert® SSL Installation Diagnostics Tool](https://www.digicert.com/help/)

### Sectigo (was Commodo)

- [Certificate Search](https://crt.sh/)

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

### Strong Ciphers TLS and SSH

[Strong Ciphers for Apache, nginx and Lighttpd and OpenSSH server settings](https://cipherli.st/)

Queries for supported algorithms

```bash
for Q in key kex cipher cipher-auth mac; do echo "--- ${Q} ---"; ssh -Q "$Q"; done
```

### Mozilla Server side TLS Tools

[Server side TLS Tools](https://ssl-config.mozilla.org/),
doc: [Server Side TLS Document](https://wiki.mozilla.org/Security/Server_Side_TLS)

### CloudFlare IP ranges

- https://www.cloudflare.com/ips-v4
- https://www.cloudflare.com/ips-v6

### CloudFlare API v4 IP banning

```
mode: block | challenge | whitelist
target: country | ip
```

Value would be an IP, /16 /24 or a 2-letter country code.
The notes field can be left empty or removed if you don't want to add any.
To block for a specific zone only, just change the API URL to:

`https://api.cloudflare.com/client/v4/zones/YOUR-ZONE-ID/firewall/packages/access_rules/rules`

Replace YOUR-ZONE-ID with the zone identifier for the zone
retrieved via an API GET to `https://api.cloudflare.com/client/v4/zones/` with your API details.

```bash
curl --data-binary '{"mode":"block","notes":"","configuration":{"value":"1.2.3.4","target":"ip"}}' \
    --compressed -H 'Content-Type: application/json' \
    --header "X-Auth-Key: $API_KEY" --header "X-Auth-Email: $API_EMAIL" --verbose \
    'https://api.cloudflare.com/client/v4/user/firewall/packages/access_rules/rules'
```

### Incapsula IP ranges

https://incapsula.zendesk.com/hc/en-us/articles/200627570-Restricting-direct-access-to-your-website-Incapsula-s-IP-addresses-

resp_format: json | apache | nginx | iptables | text

```
curl -s --data 'resp_format=apache' 'https://my.incapsula.com/api/integration/v1/ips'
```

### StackPath IP ranges

https://support.stackpath.com/hc/en-us/articles/224785167-IP-Blocks

```
curl -s https://www.maxcdn.com/one/assets/ips.txt
```

### Difference between “BEGIN RSA PRIVATE KEY” and “BEGIN PRIVATE KEY”

http://stackoverflow.com/questions/20065304/what-is-the-differences-between-begin-rsa-private-key-and-begin-private-key/20065522#20065522

### OpenVPN in Linux console

```
sudo openvpn --ca /abs/path/unsigned-ca.crt --config /abs/path/config.ovpn --auth-user-pass /abs/path/userpass --daemon
```
