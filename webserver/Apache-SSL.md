# Apache SSL

### mods-enabled/ssl.conf

```
"Intermediate" SSLCipherSuite from https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLHonorCipherOrder on
SSLProtocol all -SSLv2 -SSLv3
SSLStrictSNIVHostCheck Off
SSLCompression off

# could be in every virtual host
# OCSP Stapling
SSLUseStapling on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache "shmcb:${APACHE_RUN_DIR}/ssl_gcache_data(128000)"
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

https://www.ssllabs.com/ssltest/
https://hstspreload.appspot.com/
