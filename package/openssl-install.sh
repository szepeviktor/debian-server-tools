#!/bin/bash
#
# Compile and install OpenSSL binary from source.
#
# VERSION       :1.0.2k
# DATE          :2017-03-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# SOURCE        :https://www.openssl.org/source/
# BASH-VERSION  :4.2+

# Revision history
#
# 1.0.2k  2017-01-26
# 1.0.1j  2014-10-15

OPENSSL_CURRENT="1.0.2k"
OPENSSL_PREFIX="$(realpath .)/openssl-root"

Openssl_install()
{
    # Full install: sudo make install
    # Software without documentation: sudo make install_sw
    mkdir "$OPENSSL_PREFIX"
    make INSTALL_PREFIX="$OPENSSL_PREFIX" install
}

set -e

sudo -- apt-get install -qq zlib1g-dev

wget -nv -O - "https://openssl.org/source/openssl-${OPENSSL_CURRENT}.tar.gz" | tar -xz
cd "openssl-${OPENSSL_CURRENT}" || exit 10

# System-wide locations
# Explanation in ./INSTALL @ Configuration Options
./config --prefix=/usr zlib-dynamic --openssldir=/etc/ssl shared \
    && make && make test && Openssl_install
printf '\nexit code: %s\n' "$?" 1>&2

find "${OPENSSL_PREFIX}/usr/bin/" -type f
echo
"${OPENSSL_PREFIX}/usr/bin/openssl" version

echo "OK."
