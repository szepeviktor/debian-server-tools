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

Header always set Strict-Transport-Security "max-age=16070400; includeSubDomains"
```



### 'unknown protocol' error

In `/etc/apache2/ports.conf` put `Listen 80` last. Error:

```
SSL Library Error: error:140760FC:SSL routines:SSL23_GET_CLIENT_HELLO:unknown protocol -- speaking not SSL to HTTPS port!?
```

### CDN-s

Set CDN to HTTP/HTTPS

### SPDY

https://github.com/eousphoros/mod-spdy
Test: https://github.com/tatsuhiro-t/spdylay

### Final tests

SNI https://sni.velox.ch/
SSL https://www.ssllabs.com/ssltest/
HSTS https://hstspreload.appspot.com/
SPDY https://spdycheck.org/

### Search&Replace URL-s

And external links.
Analytics does not detect referer on redirection.
