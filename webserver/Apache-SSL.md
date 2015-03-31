# Apache SSL

### mods-enabled/ssl.conf

```
"Intermediate" SSLCipherSuite from https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLHonorCipherOrder On
SSLProtocol all -SSLv2 -SSLv3
SSLStrictSNIVHostCheck Off

SSLCompression Off

# OCSP Stapling (could also be in every virtual host)
SSLUseStapling On
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors Off
SSLStaplingCache "shmcb:${APACHE_RUN_DIR}/ssl_gcache_data(128000)"
```

### SPDY support

https://github.com/eousphoros/mod-spdy - does not support spdy/3.1
Proxy: https://github.com/tatsuhiro-t/nghttp2

### Tests

SNI https://sni.velox.ch/
SSL https://www.ssllabs.com/ssltest/
HSTS https://hstspreload.appspot.com/
SPDY CLI https://github.com/tatsuhiro-t/spdylay
SPDY https://spdycheck.org/

### Search & Replace URL-s

Set CDN to HTTP/HTTPS.
Database.
Local files.
And links on other websites pointing to this one.
Analytics does not detect referer on redirection.
