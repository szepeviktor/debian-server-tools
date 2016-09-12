# Apache SSL

### Available entropy

```bash
cat /proc/sys/kernel/random/entropy_avail
```

### Edit mods-enabled/ssl.conf

https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html

[Current master in Debian](https://anonscm.debian.org/cgit/pkg-apache/apache2.git/tree/debian/config-dir/mods-available/ssl.conf)

See [/webserver/apache-conf-available/ssl-mozilla-intermediate.default](/webserver/apache-conf-available/ssl-mozilla-intermediate.default)

### Installing CA on a server

See [/security/ca/README.md](/security/ca/README.md)

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
- SSL: https://github.com/mozilla/tls-observatory

### Moving to HTTPS

Search & Replace URL-s.

- Set CDN to HTTP/HTTPS
- Database
- Local files
- Links on other websites pointing to this one
- Analytics does not detect referer on redirection

### DH parameters

https://weakdh.org/sysadmin.html

### Clear HSTS settings

http://classically.me/blogs/how-clear-hsts-settings-major-browsers
