### Instant webserver

```bash
python3 -m http.server 80
python2 -m SimpleHTTPServer 80
```

### A web server written in Bash

https://github.com/avleen/bashttpd

### Private pull CDN

- Apache mod_proxy in shm
- http://www.symkat.com/sympull-cdn https://github.com/symkat/SymPullCDN

### Apache performance settings

https://httpd.apache.org/docs/2.4/misc/perf-tuning.html#runtime

### Measure latency/timing in Apache + PHP-FPM

1. ICMP Ping: `ping -c 10 server.example.com`
1. TCP Server: `mkfifo /tmp/fifo; cat /tmp/fifo | xargs -L 1 echo | nc -l -k 0.0.0.0 8080 > /tmp/fifo`
   TCP Client: `{ echo " * 1" | ts -- "- %.S"; sleep 1; } | nc server.example.com 8080 | ts "%.S" | bc`
1. Static HTTP Server: `echo -n "1" > onebyte.txt`
   HTTP Client: `time wget -q -O /dev/null http://server.example.com/onebyte.txt`
1. Dynmaic HTTP Server: `echo '<?php echo "1";' > onebyte.php`
   HTTP Client: `time wget -q -O /dev/null http://server.example.com/onebyte.php`

### Debug PHP-FPM (FastCGI) unix domain socket

```bash
strace $(pidof php-fpm7.2|sed 's|\b[0-9]|-p &|g') -f -e trace=read,write -s 4096 2>&1|sed 's|[A-Z_]\+|\n&|g'
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

### Quick look at the web traffic

```bash
zgrep -cH '^' /var/log/apache2/*access.log.2.gz|sort -t: -k2 -n|column -s: -t
```

### Timing details with cURL

```bash
curl -w "@curl-format.txt" -o /dev/null -s https://example.com
```

[Source](https://blog.josephscott.org/2011/10/14/timing-details-with-curl/)

### Start WordPress from CLI

```bash
REQUEST_METHOD=GET REQUEST_URI=/ HTTPS=on HTTP_HOST=$domain php index.php 2>&1 | pager
```

### CDN log format

```apache
# CDN with X-Forwarded-For header
LogFormat "%h %l %u %t \"%r\" %>s %O \"Client-IP:%{X-Forwarded-For}i\" \"%{User-Agent}i\"" cdn
```

### Apache slow loris protection

[RequestReadTimeout](https://httpd.apache.org/docs/2.4/mod/mod_reqtimeout.html)

### Disable mod_pagespeed

`?PageSpeed=off`



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

#### Caddy

https://caddyserver.com/
