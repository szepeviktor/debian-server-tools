### File revving on nginx

```nginx
location ~* ^(.+)\.\d\d+\.(js|css|png|jpg|jpeg|gif|ico)$ {
    try_files $1.$2 /index.php?$args;
}
```

### Remove all comments and indentation (compact) from a PHP script

```bash
php -w SCRIPT.php | sed 's/;/;\n/g'
```

### Experimenting with webservers

https://github.com/tatsuhiro-t/nghttp2/#nghttpx---proxy
https://github.com/tatsuhiro-t/nghttp2/wiki/ServerBenchmarkRoundH210#results
https://github.com/tatsuhiro-t/nghttp2/graphs/contributors

https://h2o.github.io/
https://github.com/h2o/h2o/issues/200 (no FastCGI support yet)
https://github.com/h2o/h2o/graphs/contributors

http://www.litespeedtech.com/products/litespeed-web-server/editions
http://www.litespeedtech.com/products/litespeed-web-server/benchmarks/php-hello-world

https://github.com/cherokee/webserver#cherokee-web-server
