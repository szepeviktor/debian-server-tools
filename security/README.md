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
# China
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
sshd: 210.0.0.0/8
sshd: 211.0.0.0/8
sshd: 218.0.0.0/8
sshd: 219.0.0.0/8
sshd: 220.0.0.0/8
sshd: 221.0.0.0/8
sshd: 222.0.0.0/8
sshd: 223.0.0.0/8
```

