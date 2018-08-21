# Apache SSL

### Available entropy

```bash
cat /proc/sys/kernel/random/entropy_avail
```

### Edit mods-enabled/ssl.conf

https://wiki.mozilla.org/Security/Server_Side_TLS

- ECDSA certificate **Speed!**
- Entropy source **Speed!**
- Protocol **TLS1.2 Speed!**
- Ciphersuites **AES-NI Speed!**
- DH parameters
- SSL session cache **Speed!**
- OCSP stapling **Speed!**
- SNI
- HSTS
- HTTP/2 **Speed!**

https://istlsfastyet.com/

[Current master in Debian](https://salsa.debian.org/apache-team/apache2/blob/master/debian/config-dir/mods-available/ssl.conf)

See [/webserver/apache-conf-available/ssl-mozilla-intermediate.default](/webserver/apache-conf-available/ssl-mozilla-intermediate.default)

### Installing CA on a server

See [/security/ca/README.md](/security/ca/README.md)

### Client certificate authentication

```apache
SSLCACertificateFile /etc/ssl/localcerts/company-ca.pem
<Location /auth>
    SSLVerifyClient require
</Location>
```

```php
    // Check verification result, CA and client CN
    $verified = (
        array_key_exists( 'SSL_CLIENT_VERIFY', $_SERVER )
        && 'SUCCESS' === $_SERVER['SSL_CLIENT_VERIFY']
        && array_key_exists( 'SSL_CLIENT_I_DN', $_SERVER )
        && $client_issuer_dn === $_SERVER['SSL_CLIENT_I_DN']
        && array_key_exists( 'SSL_CLIENT_S_DN', $_SERVER )
        && in_array( $_SERVER['SSL_CLIENT_S_DN'], $ok_client_dns )
    );
```

### Sending client certificate to iOS devices

- Import to be exported client certificates
- [Download IPCU](http://mirror.szepe.net/software/iPhoneConfigUtilitySetup.exe)
- Extract .msi packages
- Install `AppleApplicationSupport.msi` and `AppleMobileDeviceSupport64.msi` and `iPhoneConfigUtility.msi`
- `copy "C:\Program Files (x86)\Common Files\Apple\Apple Application Support\SQLite3.dll" "C:\Program Files (x86)\iPhone Configuration Utility\"`

### DH parameters

https://weakdh.org/sysadmin.html

### HTTP/2, SPDY

- https://github.com/icing/mod_h2
- https://launchpad.net/~ondrej/+archive/ubuntu/apache2
- Reverse proxy: https://github.com/tatsuhiro-t/nghttp2
- https://github.com/h2o/h2o

### Tests

- SSL: https://www.ssllabs.com/ssltest/
- SSL: https://sslanalyzer.comodoca.com/
- SSL: [Certificate Search](https://crt.sh/)
- OCSP and CRL: https://certificate.revocationcheck.com/
- SNI: https://sni.velox.ch/
- HSTS: https://hstspreload.appspot.com/
- SPDY: https://spdycheck.org/
- SPDY CLI: https://github.com/tatsuhiro-t/spdylay
- HTTP/2: https://tools.keycdn.com/http2-test
- SSL: https://github.com/mozilla/tls-observatory
- SSL: [Browser warnings](https://cryptoreport.websecurity.symantec.com/checker/views/sslCheck.jsp)

### Moving to HTTPS

Search & Replace URL-s.

- Set CDN to HTTP/HTTPS
- Database
- Local files
- Inbound links on other websites
- Analytics does not detect referer on redirection

### Clear HSTS settings

http://classically.me/blogs/how-clear-hsts-settings-major-browsers
