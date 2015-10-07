# h2o

HTTP/2-enabled webserver: server push, server hinting, header compression.

```
apt-get install -y build-essential cmake pkgconf zlib1g-dev \
    autoconf automake libtool  # For wslay
# From jessie-backports
apt-get install -y -t jessie-backports libuv1-dev

# wslay
wget -qO- https://github.com/tatsuhiro-t/wslay/archive/master.tar.gz | tar xz
cd wslay-*/
autoreconf -i
automake
autoconf
./configure
make || true
make install || true
cd ..

# h2o
wget -qO- https://github.com/h2o/h2o/archive/master.tar.gz | tar xz
cd h2o-*/
cmake -DWITH_BUNDLED_SSL=on .
make
make install
```

### Test run

`/usr/local/bin/h2o -c examples/h2o/h2o.conf`

### Browser test

`http://http2.golang.org/gophertiles`

### Debug

`chrome://net-internals/#events`

// .deb/usr/local on worker:
