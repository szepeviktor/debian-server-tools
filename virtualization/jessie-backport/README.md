# Backport Debian packages

Executes a shell script that builds a Debian package in the mounted Docker volume.

### Usage

```bash
./_start.sh "http://domain.tld/path/to/package.dsc"
# Or package name and release name
./_start.sh package/testing
```

### Hooks

See hooks documented in the Bash script.

Example hook usage in `docker-backport-munin.sh`

Packages dependencies should be placed in the mounted volume, by default `/opt/results`

### Backport Apache httpd

- openssl/jessie-backports
- spdylay
- nghttp2
- apr-util
- apache2

### Backport Courier MTA

- courier-unicode
- courier-authlib
- courier

### Backport S3QL

http://pythonhosted.org/llfuse/install.html

```bash
cat > /opt/results/debackport-init <<"EOF"
sudo chmod 0666 /dev/fuse
echo "deb http://debian-archive.trafficmanager.net/debian jessie-backports main" | sudo tee /etc/apt/sources.list.d/jessie-backports.list
EOF

cat > /opt/results/debackport-pre-deps <<"EOF"
sudo apt-get install -t jessie-backports -y python3-pytest \
    python3-py python3-pytest python3-setuptools \
    python-pytest cython3
EOF
```

1. PKG=pytest-catchlog/testing #-> python3-pytest-catchlog
1. PKG=python-llfuse/testing #-> python3-llfuse, python3-llfuse-dbg
1. PKG=python-dugong/testing #-> python3-dugong
1. PKG=s3ql/testing

`docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="$PKG" szepeviktor/jessie-backport`
