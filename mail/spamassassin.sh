#!/bin/bash

set -e -x

apt-get install -y libmail-dkim-perl \
    libsocket6-perl libsys-hostname-long-perl libnet-dns-perl libnetaddr-ip-perl \
    libcrypt-openssl-rsa-perl libdigest-hmac-perl libio-socket-inet6-perl libnet-ip-perl \
    libcrypt-openssl-bignum-perl

Getpkg spamassassin
