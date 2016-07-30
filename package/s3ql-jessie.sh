#!/bin/bash -x
#
# Install s3ql systemwide by pip only.
#
# VERSION       :2.19
# DATE          :2016-04-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://www.rath.org/s3ql-docs/installation.html#dependencies
# UPSTREAM      :https://bitbucket.org/nikratio/s3ql/downloads
# CHANGELOG     :https://bitbucket.org/nikratio/s3ql/src/default/Changes.txt

# Test in Docker
#     cp s3ql-jessie.sh s3ql-3C4E599F.asc /opt/results/
#     docker run --rm --tty -i -v /opt/results:/opt/results --entrypoint="/opt/results/s3ql-jessie.sh" szepeviktor/jessie-build

RELEASE_FILE="s3ql-2.19.tar.bz2"

set -e

# Debian packages
sudo apt-get update -qq
sudo apt-get install -y kmod fuse libattr1-dev libfuse-dev libsqlite3-dev \
    python3-pkg-resources python3-systemd \
    curl build-essential pkg-config mercurial python3-dev libjs-sphinxdoc

# Get pip
curl -s https://bootstrap.pypa.io/get-pip.py | sudo python3

# Python packages
cat > requirements.txt <<"EOF"
pycrypto
defusedxml
requests
# Must be the same version as libsqlite3
# dpkg-query --show --showformat="\${Version}" libsqlite3-dev | sed 's/-.*$/-r1/'
# 3.8.7.1-r1 for Debian jessie
apsw == 3.8.7.1-r1
# Any version between 1.0 (inclusive) and 2.0 (exclusive) will do
llfuse >= 1.0, < 2.0
# You need at least version 3.4
dugong >= 3.4, < 4.0
# optional, to run unit tests
pytest >= 2.3.3
pytest-catchlog
EOF
sudo pip3 install -r requirements.txt

# Import key "Nikolaus Rath <Nikolaus@rath.org>"
gpg --keyserver pgp.mit.edu --recv-keys 3C4E599F || gpg --import "$(dirname "$0")/s3ql-3C4E599F.asc"

# Download s3ql
curl -s -L -O -J "https://bitbucket.org/nikratio/s3ql/downloads/${RELEASE_FILE}"
curl -s -L -O -J "https://bitbucket.org/nikratio/s3ql/downloads/${RELEASE_FILE}.asc"
# Verify tarball integrity
gpg --verify "${RELEASE_FILE}.asc"

# Install s3ql
sudo pip3 install "$RELEASE_FILE"
s3qlctrl --version

rm -f "$RELEASE_FILE" "${RELEASE_FILE}.asc"

echo "OK."
