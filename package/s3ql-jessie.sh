#!/bin/bash -x
#
# Install s3ql systemwide by pip.
#
# VERSION       :2.21
# DATE          :2016-10-23
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
# Install to the Python user install directory
#     Replace `sudo pip3 install` with `pip3 install --user`
#     And add set `export PATH="~/.local/bin:${PATH}"`

RELEASE_FILE="s3ql-2.21.tar.bz2"

set -e

# Debian packages
sudo apt-get update -qq
sudo apt-get install -y fuse python3-pkg-resources python3-systemd libjs-sphinxdoc \
    curl build-essential pkg-config python3-dev libattr1-dev libfuse-dev libsqlite3-dev

# Get pip
curl -s https://bootstrap.pypa.io/get-pip.py | sudo python3

# Required packages
# https://bitbucket.org/nikratio/s3ql/src/default/setup.py#setup.py-130
sudo pip3 install pycrypto defusedxml requests "llfuse<2.0,>=1.0" "dugong<4.0,>=3.4"
# Must be the same version as Debian package libsqlite3
# dpkg-query --show --showformat="\${Version}" libsqlite3-dev | sed 's/-.*$/-r1/'
# 3.8.7.1-r1 for jessie
sudo pip3 install https://github.com/rogerbinns/apsw/releases/download/3.8.7.1-r1/apsw-3.8.7.1-r1.zip

# Import key "Nikolaus Rath <Nikolaus@rath.org>"
gpg --batch --keyserver pgp.mit.edu --keyserver-options timeout=10 --recv-keys 3C4E599F \
    || gpg --batch --import "$(dirname "$0")/s3ql-3C4E599F.asc"

# Download s3ql
curl -s -L -O -J "https://bitbucket.org/nikratio/s3ql/downloads/${RELEASE_FILE}"
curl -s -L -O -J "https://bitbucket.org/nikratio/s3ql/downloads/${RELEASE_FILE}.asc"
# Verify tarball integrity
gpg --batch --verify "${RELEASE_FILE}.asc" "$RELEASE_FILE"

# Install s3ql
sudo pip3 install "$RELEASE_FILE"
s3qlctrl --version

rm -f "$RELEASE_FILE" "${RELEASE_FILE}.asc"

# Optionally remove these packages
#apt-get purge -y curl libattr1-dev libfuse-dev libsqlite3-dev build-essential dpkg-dev pkg-config python3-dev

echo "OK."
