#!/bin/bash
#
# Issue or renew certificate by manuale and cert-update.sh
#
# VERSION       :0.1.9
# DATE          :2016-09-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# CI            :shellcheck -e SC2034 cert-update-manuale-CN.sh
# DEPENDS       :/usr/local/sbin/cert-update.sh

# Install manuale
# See LetsEncrypt.md
#
# Create a new account and register
#     manuale register "$EMAIL"
#
# Verify domain ownership by DNS
#     manuale authorize "$CN" "$DOMAIN2"
#
# Private: ${CN}.pem
# Cert:    ${CN}.crt
# Int:     ${CN}.intermediate.crt
# Chain:   ${CN}.chain.crt

# Python user install
manuale() { /usr/local/sbin/u ../../.local/bin/manuale "$@"; }

Move_challenge_files() {
    local WELL_KNOWN_ACME_CHALLENGE="$1"

    if [ ! -d "$WELL_KNOWN_ACME_CHALLENGE" ]; then
        echo "Missing .well-known/acme-challenge directory: '${WELL_KNOWN_ACME_CHALLENGE}'" 1>&2
        exit 10
    fi

    # Wait for all challenge files
    for _ in ${CN} ${DOMAIN_NAMES}; do
        sleep 5
    done
    echo

    find . -maxdepth 1 -type f -mmin -3 -regextype posix-egrep -regex '\./[0-9A-Za-z_-]{43}' -print0 \
        | xargs -r -0 -I % cp -v % "${WELL_KNOWN_ACME_CHALLENGE}/"

    # Wait for authorization
    sleep 60
    echo
    rm -v "${WELL_KNOWN_ACME_CHALLENGE}"/*
}

set -e

# Check account file
test -f account.json
manuale info
echo

# Enter domain names
read -r -p "CN=" CN
#CN="example.com"
test -n "$CN"
read -r -p "Additional domain names=" DOMAIN_NAMES
#DOMAIN_NAMES="www.${CN}"

# Private key file name
PRIV="${CN}.pem"

# Public key file name (the signed certificate)
PUB="${CN}.crt"

# Intermediate certificate file name
INT="${CN}.intermediate.crt"

# Authorize or check authorization
#     .well-known/acme-challenge
# shellcheck disable=SC2086
#Move_challenge_files "/home/USER/website/html/.well-known/acme-challenge" &
#manuale authorize --method http "$CN" ${DOMAIN_NAMES}
manuale authorize "$CN" ${DOMAIN_NAMES}

# Issue certificate
# EC key: /usr/local/sbin/u openssl ecparam -out "param-${PRIV}" -name prime256v1 -genkey
#manuale issue --key-file "param-${PRIV}" "$CN" ${DOMAIN_NAMES}
# shellcheck disable=SC2086
manuale issue "$CN" ${DOMAIN_NAMES}

# Verify signature
openssl verify -purpose sslserver -CAfile "$INT" "$PUB"

# Common variables
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"
PRIV_DIR="/etc/ssl/private"
PUB_DIR="/etc/ssl/localcerts"

# Display certificate data
printf 'CN        = '
openssl x509 -in "$PUB" -noout -subject|sed -ne 's|^.*[/=]CN \?= \?\([^/]\+\).*$|\1|p'
printf 'SAN-FIRST = '
openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^\s*DNS:\(\S\+\), .*$/\1/p}'
printf 'SAN-LAST  = '
openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}'

# Apache2: public + intermediate -------------------------
# "include intermediate CA certificates, sorted from leaf to root"

# Use Common Name as domain name
APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's|^.*[/=]CN \?= \?\([^/]\+\).*$|\1|p')"
#
# Use last Subject Alternative Name as domain name
#APACHE_DOMAIN="$(openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}')"
#
# Use first Subject Alternative Name as domain name
#APACHE_DOMAIN="$(openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^\s*DNS:\(\S\+\), .*$/\1/p}')"
#
# Replace wildcard prefix in domain name
APACHE_DOMAIN="${APACHE_DOMAIN/\*./wildcard.}"
#
# Use $APACHE_DOMAIN for determining name of the virtual host config file
APACHE_VHOST_CONFIG="/etc/apache2/sites-available/${APACHE_DOMAIN}.conf"
#
# Use ./apache.vhost for determining name of the virtual host config file
#test -s ./apache.vhost && APACHE_VHOST_CONFIG="/etc/apache2/sites-available/$(head -n 1 ./apache.vhost).conf"
#
# Uncomment to activate!
#APACHE_PUB="${PUB_DIR}/${APACHE_DOMAIN}-public.pem"
#APACHE_PRIV="${PRIV_DIR}/${APACHE_DOMAIN}-private.key"



# Courier MTA: public + intermediate + private -------------------------
# From Debian jessie on: private + public + intermediate

# Uncomment to activate!
#COURIER_COMBINED="/etc/courier/esmtpd.pem"
#COURIER_DHPARAMS="/etc/courier/dhparams.pem"
#COURIER_IMAP_COMBINED="/etc/courier/imapd.pem"



# Nginx: public + intermediate -------------------------
# "the primary certificate comes first, then the intermediate certificates"

# Use Common Name
NGINX_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')"
#
# Replace wildcard prefix
NGINX_DOMAIN="${NGINX_DOMAIN/\*./wildcard.}"
#
NGINX_VHOST_CONFIG="/etc/nginx/sites-available/${NGINX_DOMAIN}"
#
# Use nginx.vhost
test -s ./nginx.vhost && NGINX_VHOST_CONFIG="/etc/nginx/sites-available/$(head -n 1 nginx.vhost)"
#
# Uncomment to activate!
#NGINX_PUB="${PUB_DIR}/${NGINX_DOMAIN}-public.pem"
#NGINX_DHPARAM="${PRIV_DIR}/${NGINX_DOMAIN}-dhparam.pem"
#NGINX_PRIV="${PRIV_DIR}/${NGINX_DOMAIN}-private.key"



# Dovecot: public + intermediate -------------------------
# http://wiki2.dovecot.org/SSL/DovecotConfiguration#Chained_SSL_certificates

# Uncomment to activate!
#DOVECOT_PUB="/etc/dovecot/dovecot.pem"
#DOVECOT_PRIV="/etc/dovecot/private/dovecot.key"



# Proftpd -------------------------

# Uncomment to activate!
#PROFTPD_PUB="/etc/proftpd/ssl-pub.pem"
#PROFTPD_PRIV="/etc/proftpd/ssl-priv.key"
#PROFTPD_INT="/etc/proftpd/sub.class1.server.ca.pem"



# Webmin: private + public -------------------------
# SSL check: https://www.digicert.com/help/

# Uncomment to activate!
#WEBMIN_COMBINED="/etc/webmin/miniserv.pem"
#WEBMIN_INT="/etc/webmin/sub.class1.server.ca.pem"



# Execute cert-update
# shellcheck disable=SC1091
source /usr/local/sbin/cert-update.sh
