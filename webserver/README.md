### Instant webserver

```bash
python -m SimpleHTTPServer 80
```

### A web server written in Bash

https://github.com/avleen/bashttpd

### Private pull CDN

http://www.symkat.com/sympull-cdn

https://github.com/symkat/SymPullCDN

### Debug PHP-FPM (FastCGI) unix domain socket

```bash
strace $(pidof php5-fpm|sed 's|\b[0-9]|-p &|g') -f -e trace=read,write -s 4096 2>&1|sed 's|[A-Z_]\+|\n&|g'
```

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

### Remove all comments and indentation (compact) from a PHP script

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

#### LiteSpeed

http://www.litespeedtech.com/products/litespeed-web-server/editions
http://www.litespeedtech.com/products/litespeed-web-server/benchmarks/php-hello-world

#### Cherokee

https://github.com/cherokee/webserver#cherokee-web-server

#### Cowboy

http://ninenines.eu/

#### Resin

http://caucho.com/products/resin/problem

### Apache slow loris protection

[RequestReadTimeout](https://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html)

### Disable mod_pagespeed

`?PageSpeed=off`
