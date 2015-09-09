### TCP port forwarder

http://www.dest-unreach.org/socat/doc/socat.html#EXAMPLE_OPTION_REUSEADDR

```bash
socat -d -d -lmlocal2 TCP4-LISTEN:80,bind=192.168.1.1,su=nobody,fork,reuseaddr TCP4:1.2.3.4:80,bind=192.168.10.2
```

### File revving on nginx

```nginx
location ~* ^(.+)\.\d\d+\.(js|css|png|jpg|jpeg|gif|ico)$ {
    // TODO Add expiration etc. for js|css|png|jpg|jpeg|gif|ico files
    try_files $1.$2 /index.php?$args;
}
```

### Remove all comments and indentation from (compact) a PHP script

```bash
php -w SCRIPT.php | sed 's/;/;\n/g'
```

### Experimenting with webservers

#### nghttp2

https://github.com/tatsuhiro-t/nghttp2/#nghttpx---proxy
https://github.com/tatsuhiro-t/nghttp2/wiki/ServerBenchmarkRoundH210#results
https://github.com/tatsuhiro-t/nghttp2/graphs/contributors

#### H2O

https://h2o.github.io/
https://github.com/h2o/h2o/issues/200 (FastCGI support)
https://github.com/h2o/h2o/graphs/contributors

#### LiteSpeed

http://www.litespeedtech.com/products/litespeed-web-server/editions
http://www.litespeedtech.com/products/litespeed-web-server/benchmarks/php-hello-world

#### Cherokee

https://github.com/cherokee/webserver#cherokee-web-server

### Apache slow loris protection

[RequestReadTimeout](https://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html)
