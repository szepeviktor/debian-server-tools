#!/bin/bash
#
# Set up cert-update-req script and config file.
#
# VERSION       :0.2.0
# DATE          :2018-01-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :cert-update-req-CN-openssl.conf
# DEPENDS       :cert-update-req-CN.sh
# LOCATION      :/usr/local/sbin/cert-update-req-install.sh

REPO="/usr/local/src/debian-server-tools"

set -e

# You can enter wildcard.example.com
CN="$1"

CN_NAME="${CN/wildcard./*.}"

test -n "$CN"

echo "Setting up cert-update-req for ${CN_NAME} ..."

sed -e "s/@@CN@@/${CN_NAME}/g" "${REPO}/security/cert-update-req-CN-openssl.conf" \
    > "./cert-update-req-${CN}-openssl.conf"

cp -v "${REPO}/security/cert-update-req-CN.sh" "./cert-update-req-${CN}.sh"

echo "OK."

echo
echo "Set CN=\"www.${CN_NAME}\" in cert-update-req-${CN}.sh"
echo "For www: Use first Subject Alternative Name as domain name"
echo "For non-www: Use last Subject Alternative Name as domain name"
echo "Uncomment APACHE_PUB and APACHE_PRIV"
