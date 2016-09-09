# Backport Debian packages

Executes a shell script that builds a Debian package in the mounted volume.

### Usage

```bash
./_start.sh "http://domain.tld/path/to/package.dsc"
# Or package name and release name
./_start.sh package/testing
```

### Hooks

See hooks documented in the Bash script.

Example hook usage in `docker-backport-munin.sh`

Packages dependencies should be places in the mounted volume, by default `/opt/results`

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

```bash
cat > /opt/results/debackport-init <<"EOF"
echo "deb http://debian-archive.trafficmanager.net/debian jessie-backports main" | sudo tee /etc/apt/sources.list.d/jessie-backports.list
EOF
cat > /opt/results/debackport-pre-deps <<"EOF"
sudo apt-get install -t jessie-backports -y cython3 python3-py python3-pytest
EOF
```

- pytest-catchlog/testing -> python3-pytest-catchlog
- python-llfuse/testing -> python3-llfuse, python3-llfuse-dbg
- python-dugong/testing -> python3-dugong
- s3ql/testing
