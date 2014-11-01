#!/bin/bash
#
# Compile and install OpenSSL from source.
#
# VERSION       :0.1
# DATE          :2014-10-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+


# * revision history
# 1.0.1j  2014-10-15
#
# https://www.openssl.org/source/

OPENSSL_CURRENT="1.0.1j"
OPENSSL_PREFIX="$(dirname "$PWD")/$(basename "$PWD")/openssl-root"

Openssl_install() {
    # full install: sudo make install
    # the software without documentation: sudo make install_sw
    mkdir "${OPENSSL_PREFIX}"
    make INSTALL_PREFIX="$OPENSSL_PREFIX" install
}

wget -O- http://openssl.org/source/openssl-${OPENSSL_CURRENT}.tar.gz | tar -xz
cd openssl-${OPENSSL_CURRENT} || exit 10

# system-wide locations
# explanation in ./INSTALL @ Configuration Options
./config --prefix=/usr zlib-dynamic --openssldir=/etc/ssl shared \
    && make && make test && Openssl_install
echo -e "\nexit code: $?" >&2

${OPENSSL_PREFIX}/usr/bin/openssl version
