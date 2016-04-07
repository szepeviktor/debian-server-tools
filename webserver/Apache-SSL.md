# Apache SSL

### Available entropy

```bash
cat /proc/sys/kernel/random/entropy_avail
```

### Edit mods-enabled/ssl.conf

https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html

```apache
    # "Intermediate" SSLCipherSuite from Mozilla SSL Configuration Generator
    #     dpkg -l | grep "apache2\|openssl"
    #     https://mozilla.github.io/server-side-tls/ssl-config-generator/
    SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
    # As of 2016-04-05

    # @TODO When to move to https://wiki.mozilla.org/Security/Server_Side_TLS#Modern_compatibility ?

    SSLHonorCipherOrder On

    SSLProtocol all -SSLv3

    SSLStrictSNIVHostCheck Off

    SSLCompression Off

    # ??? SSLSessionTickets Off

    # OCSP Stapling (could also be in every virtual host)
    SSLUseStapling On
    SSLStaplingResponderTimeout 5
    SSLStaplingReturnResponderErrors Off
    SSLStaplingCache "shmcb:${APACHE_RUN_DIR}/ssl_gcache_data(128000)"
    SSLStaplingStandardCacheTimeout 36000

    # Root certificates
    SSLCACertificatePath /etc/ssl/certs/
    SSLCACertificateFile /etc/ssl/certs/ca-certificates.crt
```

### Installing CA on a server

See: ${D}/security/ca/README.md

### HTTP/2, SPDY

- https://github.com/icing/mod_h2
- https://launchpad.net/~ondrej/+archive/ubuntu/apache2
- Reverse proxy: https://github.com/tatsuhiro-t/nghttp2
- https://github.com/h2o/h2o

### Tests

- SSL: https://www.ssllabs.com/ssltest/
- OCSP and CRL: https://certificate.revocationcheck.com/
- SNI: https://sni.velox.ch/
- HSTS: https://hstspreload.appspot.com/
- SPDY: https://spdycheck.org/
- SPDY CLI: https://github.com/tatsuhiro-t/spdylay
- HTTP/2: https://tools.keycdn.com/http2-test
- https://github.com/mozilla/tls-observatory

### Search & Replace URL-s

- Set CDN to HTTP/HTTPS
- Database
- Local files
- Links on other websites pointing to this one
- Analytics does not detect referer on redirection

### DH parameters

https://weakdh.org/sysadmin.html

### Clear HSTS settings

http://classically.me/blogs/how-clear-hsts-settings-major-browsers
