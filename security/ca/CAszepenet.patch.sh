#!/bin/bash
#
# Customize certificate signing script.
#
# VERSION       :0.1
# DATE          :2015-04-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl
# DOCS          :https://www.debian-administration.org/article/618/Certificate_Authority_CA_with_OpenSSL

[ -f ./CAszepenet.patch ] || exit 1

cp /usr/lib/ssl/misc/CA.sh ./CAszepenet.sh \
    && patch < ./CAszepenet.patch

# Usage
#
#./CAszepenet.sh -newreq
#./CAszepenet.sh -sign
#
# Adding CA see: security/README.md
