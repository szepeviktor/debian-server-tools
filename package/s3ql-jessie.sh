#!/bin/bash
#
# Install s3ql systemwide by pip only.
#
# VERSION       :2.17.1
# DATE          :2016-04-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://www.rath.org/s3ql-docs/installation.html#dependencies
# UPSTREAM      :https://bitbucket.org/nikratio/s3ql/downloads

RELEASE_FILE="s3ql-2.17.1.tar.bz2"

cat > requirements.txt <<EOF
pycrypto
defusedxml
requests
# Must be the same version as libsqlite3
# dpkg-query --show --showformat='${Version}' libsqlite3-dev | sed 's/-.*$/-r1/'
# 3.8.7.1-r1 for Debian jessie
apsw == 3.8.7.1-r1
# Any version between 1.0 (inclusive) and 2.0 (exclusive) will do
llfuse < 2.0, >= 1.0
# You need at least version 3.4
dugong >= 3.4
EOF

# Debian packages
apt-get install -y wget build-essential python3-dev python3-pkg-resources pkg-config \
    mercurial libattr1-dev fuse libfuse-dev libsqlite3-dev libjs-sphinxdoc python3-systemd

# pip
wget -nv -O- https://bootstrap.pypa.io/get-pip.py | python3

# Python packages
pip3 install -r requirements.txt

# s3ql
wget -nv "https://bitbucket.org/nikratio/s3ql/downloads/${RELEASE_FILE}"
# @TODO Verify tarball integrity (.asc)
if pip3 install "$RELEASE_FILE"; then
    echo "OK."
else
    echo 'Failed!'
fi
