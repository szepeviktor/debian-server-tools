#!/bin/bash
#
# Install s3ql by pip.
#
# VERSION       :3.3.2
# DATE          :2019-12-26
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://www.rath.org/s3ql-docs/installation.html#installing-s3ql
# UPSTREAM      :https://github.com/s3ql/s3ql/releases
# CHANGELOG     :https://github.com/s3ql/s3ql/blob/master/Changes.txt

# Test in Docker
#     cp s3ql-jessie.sh s3ql-3C4E599F.asc /opt/results/
#     docker run --rm --tty -i -v /opt/results:/opt/results --entrypoint="/opt/results/s3ql-jessie.sh" szepeviktor/jessie-build
#
# Install to the Python user install directory
#     Replace `sudo pip3 install` with `pip3 install --user`
#     And add `export PATH="~/.local/bin:${PATH}"`

RELEASE_VERSION="3.3.2"
RELEASE_FILE="s3ql-${RELEASE_VERSION}.tar.bz2"

Pip_install()
{
    # System-wide install
    sudo pip3 --no-cache-dir install "$@"
    # User install
    #pip3 --no-cache-dir install --user "$@"
}

set -e -x

# Debian packages
sudo apt-get update -qq

sudo apt-get install -y curl python3-dev build-essential pkg-config \
    libattr1-dev libsqlite3-dev libfuse-dev fuse psmisc

# Install pip
curl -s "https://bootstrap.pypa.io/get-pip.py" | sudo python3

# Dependencies
# apsw must be the same version as Debian package libsqlite3-dev
#     dpkg-query --show --showformat="\${Version}" libsqlite3-dev | sed 's/-.*$/-r1/'
# 3.8.7.1-r1 for jessie
Pip_install "https://github.com/rogerbinns/apsw/releases/download/3.8.7.1-r1/apsw-3.8.7.1-r1.zip"
# 3.16.2-r1 for stretch
#Pip_install "https://github.com/rogerbinns/apsw/releases/download/3.16.2-r1/apsw-3.16.2-r1.zip"
# https://github.com/s3ql/s3ql/blob/master/setup.py#L138
Pip_install cryptography defusedxml requests llfuse "dugong >= 3.4, < 4.0" async_generator typing

# Import key "Nikolaus Rath <Nikolaus@rath.org>"
gpg --batch --keyserver keys2.kfwebs.net --keyserver-options timeout=10 --recv-keys "3C4E599F" \
    || gpg --batch --import "$(dirname "$0")/s3ql-3C4E599F.asc"

# Download s3ql source code
curl -s -L -O -J "https://github.com/s3ql/s3ql/releases/download/release-${RELEASE_VERSION}/${RELEASE_FILE}"
curl -s -L -O -J "https://github.com/s3ql/s3ql/releases/download/release-${RELEASE_VERSION}/${RELEASE_FILE}.asc"
# Verify tarball integrity
gpg --batch --verify "${RELEASE_FILE}.asc" "$RELEASE_FILE"

# Install S3QL
tar -xf "$RELEASE_FILE"
(
    cd "s3ql-${RELEASE_VERSION}/"
    # Do not require google-auth and google-auth-oauthlib packages
    sed -e "/'google-auth',/d" -e "s/'google-auth-oauthlib'\]/]/" -i ./setup.py
    # Build and install
    python3 ./setup.py build_ext --inplace
    python3 ./setup.py install --user
)
~/.local/bin/s3qlctrl --version
#s3qlctrl --version

rm -f "$RELEASE_FILE" "${RELEASE_FILE}.asc"

# Optionally you may remove these packages
#     apt-get purge curl python3-dev build-essential pkg-config libattr1-dev libsqlite3-dev libfuse-dev

echo "OK."
