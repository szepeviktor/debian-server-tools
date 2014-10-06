#!/bin/bash
#
# Generate certificate files for courier, proftpd and apache
# Certificate file names are hardcoded as follows
# /etc/courier/ssl-comb3.pem
# /etc/proftpd/ssl-pub.pem
# /etc/proftpd/ssl-priv.pem
# /etc/proftpd/sub.class1.server.ca.pem
# /etc/apache2/ssl-pub.pem
# /etc/apache2/ssl-priv.pem
# /etc/apache2/ca.pem
# /etc/apache2/sub.class1.server.ca.pem
#
# VERSION       :0.1
# DATE          :2014-09-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+


# StartSSL: https://www.startssl.com/certs/
# CAcert: http://www.cacert.org/index.php?id=3
# GeoTrust: https://www.geotrust.com/resources/root-certificates/
TODAY="$(date +%Y%m%d)"
CA="ca.pem"
SUB="sub.class1.server.ca.pem"
PRIV="priv-key-${TODAY}.pem"
PUB="pub-key-${TODAY}.pem"
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"

Die() {
    local RET="$1"
    shift
    echo -e "$*" >&2
    exit "$RET"
}

Readkey() {
    read -p "Press any key ..." -n 1 -s
    echo
}

if [ "$(id --user)" != 0 ]; then
    Die 1 "You need to be root."
fi
if [ "$(stat --format=%a .)" != 700 ] \
    || [ "$(stat --format=%u .)" != 0 ]; then
    Die 2 "This directory needs to be private (0700) and owned by root."
fi
if ! [ -f "$CA" ] || ! [ -f "$SUB" ] || ! [ -f "$PRIV" ] || ! [ -f "$PUB" ]; then
    Die 3 "Missing cert(s)."
fi
# check certs
PUB_MOD="$(openssl x509 -noout -modulus -in "$PUB" | openssl md5)"
PRIV_MOD="$(openssl rsa -noout -modulus -in "$PRIV" | openssl md5)"
if [ "$PUB_MOD" != "$PRIV_MOD" ]; then
    Die 4 "Mismatching certs."
fi

# protect certs
chown root:root "$CA" "$SUB" "$PRIV" "$PUB" || Die 10 "certs owner"
chmod 600 "$CA" "$SUB" "$PRIV" "$PUB" || Die 11 "certs perms"


# courier

# public + intermediate + private
COURIER_SSL="/etc/courier/ssl-comb3.pem"
cat "$PUB" "$SUB" "$PRIV" > "$COURIER_SSL" || Die 12 "courier cert creation"
chown root:daemon "$COURIER_SSL" || Die 13 "courier owner"
chmod 640 "$COURIER_SSL" || Die 14 "courier perms"
# check configs STARTTLS, SMTPS, IMAP STARTTLS IMAPS
if grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/esmtpd \
    && grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/esmtpd-ssl \
    && grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/imapd-ssl; then
    service courier-mta restart
    service courier-mta-ssl restart
    service courier-imap restart
    service courier-imap-ssl restart
    # tests
    echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:25 -starttls smtp
    echo "SMTP STARTTLS result=$?"
    Readkey
    echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:465
    echo "SMTPS result=$?"
    Readkey
    echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:143 -starttls imap
    echo "IMAP STARTTLS result=$?"
    Readkey
    echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:993
    echo "IMAPS result=$?"
else
    echo "Add 'TLS_CERTFILE=${COURIER_SSL}' to courier configs: esmtpd, esmtpd-ssl, imapd-ssl" >&2
fi
Readkey


# proftpd

PROFTPD_PUB="/etc/proftpd/ssl-pub.pem"
PROFTPD_PRIV="/etc/proftpd/ssl-priv.pem"
PROFTPS_SUB="/etc/proftpd/sub.class1.server.ca.pem"
cp "$PUB" "$PROFTPD_PUB" || Die 15 "proftpd public"
cp "$PRIV" "$PROFTPD_PRIV" || Die 16 "proftpd private"
cp "$SUB" "$PROFTPS_SUB" || Die 17 "proftpd intermediate"
chown root:root "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPS_SUB" || Die 18 "proftpd owner"
chmod 640 "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPS_SUB" || Die 19 "proftp perms"
# check config
if  grep -q "^TLSRSACertificateFile\s*${PROFTPD_PUB}\$" /etc/proftpd/tls.conf \
    && grep -q "^TLSRSACertificateKeyFile\s*${PROFTPD_PRIV}\$" /etc/proftpd/tls.conf \
    && grep -q "^TLSCACertificateFile\s*${PROFTPS_SUB}\$" /etc/proftpd/tls.conf; then
    service proftpd restart
    # test
    echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:21 -starttls ftp
    echo "AUTH TLS result=$?"
else
    echo "Edit ProFTPd TLSRSACertificateFile, TLSRSACertificateKeyFile and TLSCACertificateFile" >&2
fi
Readkey


# apache

APACHE_PUB="/etc/apache2/ssl-pub.pem"
APACHE_PRIV="/etc/apache2/ssl-priv.pem"
APACHE_CA="/etc/apache2/ca.pem"
APACHE_SUB="/etc/apache2/sub.class1.server.ca.pem"
cp "$PUB" "$APACHE_PUB" || Die 20 "apache public"
cp "$PRIV" "$APACHE_PRIV" || Die 21 "apache private"
cp "$CA" "$APACHE_CA" || Die 22 "apache certificate authority"
cp "$SUB" "$APACHE_SUB" || Die 23 "apache intermediate"
chown root:root "$APACHE_PUB" "$APACHE_PRIV" "$APACHE_CA" "$APACHE_SUB" || Die 24 "apache owner"
chmod 640 "$APACHE_PUB" "$APACHE_PRIV" "$APACHE_CA" "$APACHE_SUB" || Die 25 "apache perms"
# check config
if  grep -q "^\s*SSLCertificateFile\s*${APACHE_PUB}\$" /etc/apache2/sites-available/default-ssl \
    && grep -q "^\s*SSLCertificateKeyFile\s*${APACHE_PRIV}\$" /etc/apache2/sites-available/default-ssl \
    && grep -q "^\s*SSLCACertificateFile\s*${APACHE_CA}\$" /etc/apache2/sites-available/default-ssl \
    && grep -q "^\s*SSLCertificateChainFile\s*${APACHE_SUB}\$" /etc/apache2/sites-available/default-ssl; then
    service apache2 restart
    # test
    timeout 3 openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:443
    echo "HTTPS result=$?"
else
    echo "Edit Apache SSLCertificateFile, SSLCertificateKeyFile, SSLCACertificateFile and SSLCertificateChainFile" >&2
fi
# skip last Readkey

echo "Done."
