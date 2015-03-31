#!/bin/bash
#
# Generate certificate files for courier-mta, proftpd and apache2.
# Also for Webmin and Dovecot.
#
# VERSION       :0.4
# DATE          :2015-02-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl ca-certificates

# Various root certificates
#
# StartSSL: https://www.startssl.com/certs/
#   wget https://www.startssl.com/certs/ca.pem
#   wget https://www.startssl.com/certs/sub.class1.server.ca.pem
# GeoTrust: https://www.geotrust.com/resources/root-certificates/
# CAcert: http://www.cacert.org/index.php?id=3
# NetLock: https://www.netlock.hu/html/cacrl.html

# Saving certificate from the issuer
#
# e "priv-key-$(date +%Y%m%d)-encrypted.key"
# openssl rsa -in "priv-key-$(date +%Y%m%d)-encrypted.key" -out "priv-key-$(date +%Y%m%d).key"
# e "pub-key-$(date +%Y%m%d).key"

TODAY="$(date +%Y%m%d)"
CA="ca.pem"
SUB="sub.class1.server.ca.pem"
PRIV="priv-key-${TODAY}.key"
PUB="pub-key-${TODAY}.pem"
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"

# courier-mta: public + intermediate + private
COURIER_SSL="/etc/courier/ssl-comb3.pem"

# proftpd
#PROFTPD_PUB="/etc/proftpd/ssl-pub.pem"
#PROFTPD_PRIV="/etc/proftpd/ssl-priv.key"
#PROFTPD_SUB="/etc/proftpd/sub.class1.server.ca.pem"

# apache2: public + intermediate
# "include intermediate CA certificates, sorted from leaf to root"
APACHE_DOMAIN="domain.tld"
APACHE_SSL_CONFIG="/etc/apache2/sites-available/${APACHE_DOMAIN}.conf"
APACHE_PUB="/etc/apache2/ssl/${APACHE_DOMAIN}-public.pem"
APACHE_PRIV="/etc/apache2/ssl/${APACHE_DOMAIN}-private.key"

# dovecot: public + intermediate
# http://wiki2.dovecot.org/SSL/DovecotConfiguration#Chained_SSL_certificates
#DOVECOT_PUB="/etc/dovecot/dovecot.pem"
#DOVECOT_PRIV="/etc/dovecot/private/dovecot.key"

# webmin: private + public
# SSL check: https://www.digicert.com/help/
#WEBMIN_SSL="/etc/webmin/miniserv.pem"
#WEBMIN_SUB="/etc/webmin/sub.class1.server.ca.pem"

########################################

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

Check_requirements() {
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
}

Protect_certs() {
    # also check cers are readable
    chown root:root "$CA" "$SUB" "$PRIV" "$PUB" || Die 10 "certs owner"
    chmod 600 "$CA" "$SUB" "$PRIV" "$PUB" || Die 11 "certs perms"
}

Courier_mta() {
    [ -z "$COURIER_SSL" ] && return 1

    cat "$PUB" "$SUB" "$PRIV" > "$COURIER_SSL" || Die 12 "courier cert creation"
    chown root:daemon "$COURIER_SSL" || Die 13 "courier owner"
    chmod 640 "$COURIER_SSL" || Die 14 "courier perms"

    # check config files for STARTTLS, SMTPS, IMAP STARTTLS IMAPS
    if grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/esmtpd \
        && grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/esmtpd-ssl \
        && grep -q "^TLS_CERTFILE=${COURIER_SSL}\$" /etc/courier/imapd-ssl; then

        service courier-mta restart
        service courier-mta-ssl restart
        service courier-imap restart
        service courier-imap-ssl restart

        # tests SMTP, SMTPS, IMAP, IMAPS
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
}

Proftpd() {
    [ -z "$PROFTPD_PUB" ] && return 1
    [ -z "$PROFTPD_PRIV" ] && return 1
    [ -z "$PROFTPD_SUB" ] && return 1

    cp "$PUB" "$PROFTPD_PUB" || Die 15 "proftpd public"
    cp "$PRIV" "$PROFTPD_PRIV" || Die 16 "proftpd private"
    cp "$SUB" "$PROFTPD_SUB" || Die 17 "proftpd intermediate"
    chown root:root "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPD_SUB" || Die 18 "proftpd owner"
    chmod 600 "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPD_SUB" || Die 19 "proftpd perms"

    # check config
    if  grep -q "^TLSRSACertificateFile\s*${PROFTPD_PUB}\$" /etc/proftpd/tls.conf \
        && grep -q "^TLSRSACertificateKeyFile\s*${PROFTPD_PRIV}\$" /etc/proftpd/tls.conf \
        && grep -q "^TLSCACertificateFile\s*${PROFTPD_SUB}\$" /etc/proftpd/tls.conf; then

        service proftpd restart

        # test FTP
        echo "QUIT"|openssl s_client -crlf -CAfile "$CABUNDLE" -connect localhost:21 -starttls ftp
        echo "AUTH TLS result=$?"
    else
        echo "Edit ProFTPd TLSRSACertificateFile, TLSRSACertificateKeyFile and TLSCACertificateFile" >&2
    fi
}

Apache2() {
    [ -z "$APACHE_PUB" ] && return 1
    [ -z "$APACHE_PRIV" ] && return 1
    [ -z "$APACHE_SSL_CONFIG" ] && return 1

    cat "$PUB" "$SUB" > "$APACHE_PUB" || Die 20 "apache cert creation"
    cp "$PRIV" "$APACHE_PRIV" || Die 21 "apache private"
    chown root:root "$APACHE_PUB" "$APACHE_PRIV" || Die 23 "apache owner"
    chmod 640 "$APACHE_PUB" "$APACHE_PRIV" || Die 24 "apache perms"

    # check config
    if  grep -q "^\s*SSLCertificateFile\s\+${APACHE_PUB}\$" "$APACHE_SSL_CONFIG" \
        && grep -q "^\s*SSLCertificateKeyFile\s\+${APACHE_PRIV}\$" "$APACHE_SSL_CONFIG" \
        && grep -q "^\s*SSLCACertificatePath\s\+/etc/ssl/certs\$" "$APACHE_SSL_CONFIG" \
        && grep -q "^\s*SSLCACertificateFile\s\+${CABUNDLE}\$" "$APACHE_SSL_CONFIG"; then

        service apache2 restart

        # test HTTPS
        SERVER_NAME="$(grep -i -o -m1 "ServerName\s\+\S\+" "$APACHE_SSL_CONFIG"|cut -d' ' -f2)"
        timeout 3 openssl s_client -CAfile "$CABUNDLE" -connect ${SERVER_NAME}:443
        echo "HTTPS result=$?"
    else
        echo "Edit Apache SSLCertificateFile, SSLCertificateKeyFile, SSLCACertificatePath and SSLCACertificateFile" >&2
    fi
}

Dovecot() {
    [ -z "$DOVECOT_PUB" ] && return 1
    [ -z "$DOVECOT_PRIV" ] && return 1

    # dovecot: public + intermediate
    cat "$PUB" "$SUB" > "$DOVECOT_PUB" || Die 26 "dovecot cert creation"
    cat "$PRIV" > "$DOVECOT_PRIV" || Die 27 "dovecot private cert creation"
    chown root:root "$DOVECOT_PUB" "$DOVECOT_PRIV" || Die 28 "dovecot owner"
    chmod 600 "$DOVECOT_PUB" "$DOVECOT_PRIV" || Die 29 "dovecot perms"

    # check config files for ssl_cert, ssl_key
    if grep -q "^ssl_cert\s*=\s*<${DOVECOT_PUB}\$" /etc/dovecot/conf.d/10-ssl.conf \
        && grep -q "^ssl_key\s*=\s*<${DOVECOT_PRIV}\$" /etc/dovecot/conf.d/10-ssl.conf; then

        service dovecot restart

        # tests POP3, POP3S, IMAP, IMAPS
        echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:110 -starttls pop3
        echo "POP3 STARTTLS result=$?"
        Readkey
        echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:995
        echo "POP3S result=$?"
        Readkey
        echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:143 -starttls imap
        echo "IMAP STARTTLS result=$?"
        Readkey
        echo QUIT|openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:993
        echo "IMAPS result=$?"
    else
        echo "Edit Dovecot ssl_cert and ssl_key" >&2
    fi
}

Webmin() {
    [ -z "$WEBMIN_SSL" ] && return 1
#FIXME: could be a separate public key: "certfile="
    [ -z "$WEBMIN_SUB" ] && return 1

    # webmin: private + public
    cat "$PRIV" "$PUB" > "$WEBMIN_SSL" || Die 30 "webmin public"
    cp "$SUB" "$WEBMIN_SUB" || Die 31 "webmin intermediate"
    chown root:root "$WEBMIN_SSL" "$WEBMIN_SUB" || Die 32 "webmin owner"
    chmod 600 "$WEBMIN_SSL" "$WEBMIN_SUB" || Die 33 "webmin perms"

    # check config
    if  grep -q "^keyfile=${WEBMIN_SSLL}\$" /etc/webmin/miniserv.conf \
        && grep -q "^extracas=${WEBMIN_SUB}\$" /etc/webmin/miniserv.conf; then

        service webmin restart

        # test HTTPS:10000
        timeout 3 openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:10000
        echo "HTTPS result=$?"
    else
        echo "Edit Webmin keyfile and extracas" >&2
    fi
}

Check_requirements
Protect_certs

Courier_mta && Readkey

Proftpd && Readkey

Apache2 && Readkey

Dovecot && Readkey

Webmin
# no ReadKey at last

echo "Done."
