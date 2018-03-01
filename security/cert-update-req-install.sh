#!/bin/bash
#
# Set up cert-update-req script and config file.
#
# VERSION       :0.1.0
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

CN="$1"
test -n "$CN"
echo "Setting up cert-update-req for ${CN} ..."

sed -e "s/@@CN@@/${CN}/g" "${REPO}/security/cert-update-req-CN-openssl.conf" > "./cert-update-req-${CN}-openssl.conf"

cp -v "${REPO}/security/cert-update-req-CN.sh" "./cert-update-req-${CN}.sh"

echo "OK."
