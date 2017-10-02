#!/bin/bash

set -e -x

apt-get install -y libmail-dkim-perl \
    libsocket6-perl libsys-hostname-long-perl libnet-dns-perl libnetaddr-ip-perl \
    libcrypt-openssl-rsa-perl libdigest-hmac-perl libio-socket-inet6-perl libnet-ip-perl \
    libcrypt-openssl-bignum-perl

Getpkg spamassassin

# Rule updating
# # SVN revision lookup by reverse version number
# host -t TXT 1.4.3.updates.spamassassin.org.
# # Get mirror URL
# wget https://svn.apache.org/repos/asf/spamassassin/site/updates/MIRRORED.BY
# # Download rules
# wget ${MIRROR_URL}/${SVN_REVISION}.tar.gz
