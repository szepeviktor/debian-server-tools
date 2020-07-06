#!/bin/bash
#
# Config file and loader for cert-update.sh.
#
# VERSION       :0.2.9
# DATE          :2018-06-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :/usr/local/sbin/cert-update.sh

# Intermediate certificates and root certificates
#
# RapidSSL
#     https://knowledge.digicert.com/generalinformation/INFO1548
#     https://products.geotrust.com/geocenter/reissuance/reissue.do
# PositiveSSL, ComodoSSL, EssentialSSL
#     https://support.comodo.com/index.php?/Default/Knowledgebase/Article/View/620/0/which-is-root-which-is-intermediate
# GeoTrust
#     https://www.geotrust.com/resources/root-certificates/
# Let’s Encrypt
#     wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
#     https://letsencrypt.org/certificates/
# NetLock (HU)
#     https://netlock.hu/tanusitvanykiadok/
# Microsec (HU)
#     https://e-szigno.hu/hitelesites-szolgaltatas/tanusitvanyok/szolgaltatoi-tanusitvanyok.html
# szepenet (own)
#     wget http://ca.szepe.net/szepenet-ca.pem

set -e

# Current date
TODAY="$(date --utc "+%Y%m%d")"
#TODAY="$(date --utc --date "1 day ago" "+%Y%m%d")"

# Private key file name
PRIV="priv-key-${TODAY}.key"

# Public key file name (the signed certificate)
PUB="pub-key-${TODAY}.pem"

# Intermediate certificate file name
INT="intermediate.pem"
#INT="null.crt"; touch "$INT"

# Certificate signing request
CSR="request-${TODAY}.csr"

# Certificate name for directory and file names (not Common Name)
read -r -p "Certificate name? " CN
#CN="www.example.com"
test -n "$CN"

CERT_DIR="./${TODAY}-${CN}"
test -d "$CERT_DIR" || mkdir -m 0700 "$CERT_DIR"
cd "$CERT_DIR"

# CSR generation mode
if [ ! -s "$PRIV" ]; then
    # Generate private key
    openssl genrsa -out "$PRIV" 2048
    ## EC private key
    ## https://en.wikipedia.org/wiki/Comparison_of_TLS_implementations#Supported_elliptic_curves
    #openssl ecparam -out "$PRIV" -name prime256v1 -genkey
    openssl rsa -in "$PRIV" -noout -text
    read -r -s -n 1 -p "Check private key and press any key ..."
    echo

    # Generate request
    if [ -f "../cert-update-req-${CN}-openssl.conf" ]; then
        cp "../cert-update-req-${CN}-openssl.conf" "${CN}-openssl.conf"
    elif [ -f "../cert-update-req-${CN#www.}-openssl.conf" ]; then
        cp "../cert-update-req-${CN#www.}-openssl.conf" "${CN}-openssl.conf"
    fi
    editor "${CN}-openssl.conf"
    test -s "${CN}-openssl.conf"
    openssl req -out "$CSR" -new -key "$PRIV" \
        -config "${CN}-openssl.conf" -utf8 -verbose
    openssl req -in "$CSR" -noout -text
    read -r -s -n 1 -p "Check request and press any key ..."
    echo
    cat "$CSR"
    read -r -s -n 1 -p "Copy CSR and press any key ..."
    echo

    # Get certificate from a CA!

    # HTTP validation file (e.g. for RapidSSL, AS13649 ViaWest, "DigiCert DCV Bot/1.1")
    echo
    echo "http://${CN}/.well-known/pki-validation/fileauth.txt"

    exit 0
fi

# Enter public key, the signed certificate
editor "$PUB"
# Enter intermediate certificate
editor "$INT"
# Verify signature
openssl verify -purpose sslserver -CAfile "$INT" "$PUB"


# Common variables
# shellcheck disable=SC2034
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"
# shellcheck disable=SC2034
PRIV_DIR="/etc/ssl/private"
# shellcheck disable=SC2034
PUB_DIR="/etc/ssl/localcerts"



# Apache2: public + intermediate -------------------------
# "include intermediate CA certificates, sorted from leaf to root"

# Use Common Name as domain name
# shellcheck disable=SC2034
APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's|^.*[/=]CN \?= \?\([^/]\+\).*$|\1|p')"
#
# Use last Subject Alternative Name as domain name
# shellcheck disable=SC2034
#APACHE_DOMAIN="$(openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}')"
#
# Use first Subject Alternative Name as domain name
# shellcheck disable=SC2034
#APACHE_DOMAIN="$(openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^\s*DNS:\(\S\+\), .*$/\1/p}')"
#
# Replace wildcard prefix in domain name
# shellcheck disable=SC2034
APACHE_DOMAIN="${APACHE_DOMAIN/\*./wildcard.}"
#
# Use $APACHE_DOMAIN for determining name of the virtual host config file
# shellcheck disable=SC2034
APACHE_VHOST_CONFIG="/etc/apache2/sites-available/${APACHE_DOMAIN}.conf"
#
# Use ./apache.vhost for determining name of the virtual host config file
# shellcheck disable=SC2034
test -s ./apache.vhost && APACHE_VHOST_CONFIG="/etc/apache2/sites-available/$(head -n 1 ./apache.vhost).conf"
#
# Uncomment to activate!
# shellcheck disable=SC2034
#APACHE_PUB="${PUB_DIR}/${APACHE_DOMAIN}-public.pem"
# shellcheck disable=SC2034
#APACHE_PRIV="${PRIV_DIR}/${APACHE_DOMAIN}-private.key"



# Courier MTA: public + intermediate + private -------------------------
# From Debian jessie on: private + public + intermediate

# Uncomment to activate!
# shellcheck disable=SC2034
#COURIER_COMBINED="/etc/courier/esmtpd.pem"
# shellcheck disable=SC2034
#COURIER_DHPARAMS="/etc/courier/dhparams.pem"
# shellcheck disable=SC2034
#COURIER_IMAP_COMBINED="/etc/courier/imapd.pem"



# Nginx: public + intermediate -------------------------
# "the primary certificate comes first, then the intermediate certificates"

# Use Common Name
# shellcheck disable=SC2034
NGINX_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')"
#
# Replace wildcard prefix
# shellcheck disable=SC2034
NGINX_DOMAIN="${NGINX_DOMAIN/\*./wildcard.}"
#
# shellcheck disable=SC2034
NGINX_VHOST_CONFIG="/etc/nginx/sites-available/${NGINX_DOMAIN}"
#
# Use nginx.vhost
# shellcheck disable=SC2034
test -s ./nginx.vhost && NGINX_VHOST_CONFIG="/etc/nginx/sites-available/$(head -n 1 nginx.vhost)"
#
# Uncomment to activate!
# shellcheck disable=SC2034
#NGINX_PUB="${PUB_DIR}/${NGINX_DOMAIN}-public.pem"
# shellcheck disable=SC2034
#NGINX_DHPARAM="${PRIV_DIR}/${NGINX_DOMAIN}-dhparam.pem"
# shellcheck disable=SC2034
#NGINX_PRIV="${PRIV_DIR}/${NGINX_DOMAIN}-private.key"



# Dovecot: public + intermediate -------------------------
# http://wiki2.dovecot.org/SSL/DovecotConfiguration#Chained_SSL_certificates

# Uncomment to activate!
# shellcheck disable=SC2034
#DOVECOT_PUB="/etc/dovecot/dovecot.pem"
# shellcheck disable=SC2034
#DOVECOT_PRIV="/etc/dovecot/private/dovecot.key"



# Proftpd -------------------------

# Uncomment to activate!
# shellcheck disable=SC2034
#PROFTPD_PUB="/etc/proftpd/ssl-pub.pem"
# shellcheck disable=SC2034
#PROFTPD_PRIV="/etc/proftpd/ssl-priv.key"
# shellcheck disable=SC2034
#PROFTPD_INT="/etc/proftpd/sub.class1.server.ca.pem"



# Webmin: private + public -------------------------
# SSL check: https://www.digicert.com/help/

# Uncomment to activate!
# shellcheck disable=SC2034
#WEBMIN_COMBINED="/etc/webmin/miniserv.pem"
# shellcheck disable=SC2034
#WEBMIN_INT="/etc/webmin/sub.class1.server.ca.pem"



# Execute cert-update
# shellcheck disable=SC1091
source /usr/local/sbin/cert-update.sh
