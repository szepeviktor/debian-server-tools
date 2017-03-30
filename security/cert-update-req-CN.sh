#!/bin/bash
#
# Config file and loader for cert-update.sh.
#
# VERSION       :0.2.1
# DATE          :2016-09-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# CI            :shellcheck -e SC2034 cert-update-req-CN.sh
# DEPENDS       :/usr/local/sbin/cert-update.sh

# Intermediate certificates and root certificates
#
# Let’s Encrypt
#     wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem
#     https://letsencrypt.org/certificates/
# ComodoSSL, EssentialSSL, PositiveSSL
#     https://support.comodo.com/index.php?/Default/Knowledgebase/Article/View/620/0/which-is-root-which-is-intermediate
# GeoTrust
#     https://www.geotrust.com/resources/root-certificates/
# RapidSSL
#     https://knowledge.rapidssl.com/support/ssl-certificate-support/index?page=content&id=INFO1548
# NetLock (HU)
#     https://www.netlock.hu/html/cacrl.html
# Microsec (HU)
#     https://e-szigno.hu/hitelesites-szolgaltatas/tanusitvanyok/szolgaltatoi-tanusitvanyok.html
# szepenet
#     wget http://ca.szepe.net/szepenet-ca.pem
# StartSSL Class 1 DV (Domain and Email Validation)
#     https://www.startssl.com/root "Intermediate CA Certificates"
#     wget https://www.startssl.com/certs/sca.server1.crt && dos2unix sca.server1.crt
# StartSSL Class 2 IV (Identity Validation)
#     wget https://www.startssl.com/certs/sca.server2.crt && dos2unix sca.server2.crt
# StartSSL Class 3 OV (Organization Validation)
#     wget https://www.startssl.com/certs/sca.server3.crt && dos2unix sca.server3.crt
#
# $CN-openssl.conf
#     [ req ]
#     prompt = no
#     default_bits = 2048
#     default_md = sha256
#     distinguished_name = req_distinguished_name
#     req_extensions = v3_req
#     oid_section = new_oids
#
#     [ req_distinguished_name ]
#     CN = EDIT
#     C = EDIT
#     ST = EDIT
#     L = EDIT
#     O = EDIT
#     emailAddress = EDIT
#
#     [ new_oids ]
#     # http://oid-info.com/get/2.5.4.17
#     postalCode = 2.5.4.17
#     streetAddress = 2.5.4.9
#     jurisdictionOfIncorporationCountryName = 1.3.6.1.4.1.311.60.2.1.3
#     businessCategory = 2.5.4.15
#
#     [ v3_req ]
#     subjectAltName = @alt_names
#
#     [ alt_names ]
#     DNS.1 = EDIT
#     DNS.2 = www.EDIT

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

# Storage directory from canonical name
read -r -p "CN=" CN
#CN="example.com"

test -n "$CN"
CERT_DIR="/root/ssl/${TODAY}-${CN}"
# shellcheck disable=SC2174
mkdir -p -m 0700 "$CERT_DIR"
cd "$CERT_DIR"

# Generate private key
openssl genrsa -out "$PRIV" 2048
# https://en.wikipedia.org/wiki/Comparison_of_TLS_implementations#Supported_elliptic_curves
# EC key: openssl ecparam -out "$PRIV" -name prime256v1 -genkey
openssl rsa -in "$PRIV" -noout -text
read -r -s -n 1 -p "Check private key and press any key ..."

# Generate request
editor "${CN}-openssl.conf"
test -s "${CN}-openssl.conf"
openssl req -out "$CSR" -new -key "$PRIV" -sha256 \
    -config "${CN}-openssl.conf" -verbose
openssl req -in "$CSR" -noout -text
read -r -s -n 1 -p "Check request and press any key ..."
echo
cat "$CSR"
read -r -s -n 1 -p "Copy CSR and press any key ..."

# Get certificate from a CA!

# HTTP validation file
echo
echo "http://${CN}/.well-known/pki-validation/fileauth.txt"
read -r -s -n 1 -p "Create fileauth.txt and press any key ..."

# Enter intermediate certificate
editor "$INT"
# Enter public key, the signed certificate
editor "$PUB"
# Verify signature
openssl verify -purpose sslserver -CAfile "$INT" "$PUB"


# Common variables
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"
PRIV_DIR="/etc/ssl/private"
PUB_DIR="/etc/ssl/localcerts"



# Apache2: public + intermediate -------------------------
# "include intermediate CA certificates, sorted from leaf to root"

# Use Common Name as domain name
APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')"
#
# Use last Subject Alternative Name as domain name
#APACHE_DOMAIN="$(openssl x509 -in "$PUB" -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}')"
#
# Replace wildcard prefix in domain name
APACHE_DOMAIN="${APACHE_DOMAIN/\*./wildcard.}"
#
#
# Use $APACHE_DOMAIN for determining name of the virtual host config file
APACHE_VHOST_CONFIG="/etc/apache2/sites-available/${APACHE_DOMAIN}.conf"
#
# Use ./apache.vhost for determining name of the virtual host config file
[ -s ./apache.vhost ] && APACHE_VHOST_CONFIG="/etc/apache2/sites-available/$(head -n 1 ./apache.vhost).conf"
#
# Uncomment to activate!
#APACHE_PUB="${PUB_DIR}/${APACHE_DOMAIN}-public.pem"
#APACHE_PRIV="${PRIV_DIR}/${APACHE_DOMAIN}-private.key"



# Courier MTA: public + intermediate + private -------------------------
# From Debian jessie on: private + public + intermediate

# Uncomment to activate!
#COURIER_COMBINED="/etc/courier/esmtpd.pem"
#COURIER_DHPARAMS="/etc/courier/dhparams.pem"



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
[ -s ./nginx.vhost ] && NGINX_VHOST_CONFIG="/etc/nginx/sites-available/$(head -n 1 nginx.vhost)"
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
