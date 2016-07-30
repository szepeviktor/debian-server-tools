### Apache backport

- openssl/jessie-backports
- spdylay
- nghttp2
- apr-util
- apache2

### Courier backport

- courier-unicode
- courier-authlib
- courier

### S3QL backport

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
