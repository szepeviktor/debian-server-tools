#!/bin/bash
#
# Set up certificate for use.
#
# VERSION       :1.3.1
# DATE          :2018-08-26
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# ERRORCODES    :grep -o 'Die [0-9].*$' cert-update.sh|sort -k2 -n|cut -d' ' -f1-2|uniq -d
# DEPENDS       :apt-get install openssl ca-certificates
# LOCATION      :/usr/local/sbin/cert-update.sh

# Usage
#
# See cert-update-manuale-CN.sh

# @TODO Add apache SSLOpenSSLConfCmd for OpenSSL 1.0.2+

Die()
{
    local RET="$1"
    shift
    echo -e "$*" 1>&2
    exit "$RET"
}

Readkey()
{
    read -r -p "[cert-update.sh] Press any key ..." -n 1 -s
    echo
}

Check_requirements()
{
    if [[ $EUID -ne 0 ]]; then
        Die 124 "You need to be root."
    fi
    if [ "$(stat --format=%a .)" != 700 ]; then
        Die 10 "This directory needs to be private (0700)."
    fi
    if [ ! -f "$INT" ] || [ ! -f "$PRIV" ] || [ ! -f "$PUB" ] || [ ! -f "$CABUNDLE" ]; then
        Die 11 "Missing cert or CA bundle."
    fi
    if [ ! -d "$PRIV_DIR" ] || [ ! -d "$PUB_DIR" ]; then
        Die 12 "Missing cert directory."
    fi
    # ssl-cert packages sets it to 0710 and root:ssl-cert as owner and group.
    if [ "$(stat --format=%a "$PRIV_DIR")" != 700 ] \
        || [ "$(stat --format=%u "$PRIV_DIR")" != 0 ]; then
        Die 13 "Private cert directory needs to be private (0700) and owned by root."
    fi
    if [ ! -f /usr/local/sbin/cert-expiry.sh ] || [ ! -f /etc/cron.weekly/cert-expiry1 ]; then
        Die 14 "./install.sh monitoring/cert-expiry.sh"
    fi

    # Check certificates
    if openssl x509 -in "$PUB" -noout -text | grep -q -x '\s*Public Key Algorithm:\s\+id-ecPublicKey'; then
        PRIV_MOD="$(openssl pkey -pubout -in "$PRIV" | openssl sha256)"
        PUB_MOD="$(openssl x509 -noout -pubkey -in "$PUB" | openssl sha256)"
    else
        PRIV_MOD="$(openssl rsa -noout -modulus -in "$PRIV" | openssl sha256)"
        PUB_MOD="$(openssl x509 -noout -modulus -in "$PUB" | openssl sha256)"
    fi
    if [ "$PUB_MOD" != "$PRIV_MOD" ]; then
        Die 15 "Mismatching certs."
    fi

    # Verify public cert is signed by the intermediate cert if intermediate is present
    if [ -s "$INT" ] && ! openssl verify -purpose sslserver -CAfile "$INT" "$PUB" | grep -qFx "${PUB}: OK"; then
        Die 16 "Mismatching intermediate cert."
    fi
}

Protect_certs()
{
    # Are certificates readable?
    ## New non-root issuance
    ##chown root:root "$INT" "$PRIV" "$PUB" || Die 18 "certs owner"
    chmod 0600 "$INT" "$PRIV" "$PUB" || Die 19 "certs perms"
}

Apache2()
{
    test -z "$APACHE_PUB" && return 125
    test -z "$APACHE_PRIV" && return 125
    test -r "$APACHE_VHOST_CONFIG" || return 125

    test -d "$(dirname "$APACHE_PUB")" || Die 40 "apache ssl dir"

    echo "Installing Apache certificate ..."
    {
        cat "$PUB" "$INT"
        if ! openssl x509 -in "$PUB" -noout -text | grep -q -x '\s*Public Key Algorithm:\s\+id-ecPublicKey'; then
            #nice openssl dhparam 4096
            nice openssl dhparam 2048
        fi
    } >"$APACHE_PUB" || Die 41 "apache cert creation"
    cp "$PRIV" "$APACHE_PRIV" || Die 42 "apache private"
    chown root:root "$APACHE_PUB" "$APACHE_PRIV" || Die 43 "apache owner"
    chmod 0640 "$APACHE_PUB" "$APACHE_PRIV" || Die 44 "apache perms"

    # Check SSL config (symlink)
    if [ ! -h /etc/apache2/mods-enabled/ssl.conf ]; then
        Die 47 "apache SSL configuration"
    fi
    # Check config
    SITE_DOMAIN="$(sed -n -e '0,/^\s*Define\s\+SITE_DOMAIN\s\+\(\S\+\)\s*$/s||\1|p' "$APACHE_VHOST_CONFIG")"
    test -z "$SITE_DOMAIN" && Die 45 "apache SITE_DOMAIN"
    SERVER_NAME="$(sed -n -e '0,/^\s*ServerName\s\+\(\S\+\)\s*$/s||\1|p' "$APACHE_VHOST_CONFIG")"
    SERVER_NAME="${SERVER_NAME/\$\{SITE_DOMAIN\}/${SITE_DOMAIN}}"
    test -z "$SERVER_NAME" && Die 46 "apache ServerName"
    if sed -e "s|\${SITE_DOMAIN}|${SITE_DOMAIN}|g" "$APACHE_VHOST_CONFIG" \
        | grep -q -x "\\s*SSLCertificateFile\\s\\+${APACHE_PUB}" \
        && sed -e "s|\${SITE_DOMAIN}|${SITE_DOMAIN}|g" "$APACHE_VHOST_CONFIG" \
        | grep -q -x "\\s*SSLCertificateKeyFile\\s\\+${APACHE_PRIV}"; then

        apache2ctl configtest && service apache2 reload

        # Test HTTPS
        echo -n | openssl s_client -CAfile "$CABUNDLE" -servername "$SERVER_NAME" -connect "${SERVER_NAME}:443"
        echo "HTTPS result=$?"
        echo -n | openssl s_client -CAfile "$CABUNDLE" -servername "$SERVER_NAME" \
            -connect "${SERVER_NAME}:443" 2>/dev/null | openssl x509 -noout -dates
    else
        echo "Edit Apache SSLCertificateFile, SSLCertificateKeyFile" 1>&2
        echo "echo -n|openssl s_client -CAfile ${CABUNDLE} -servername ${SERVER_NAME} -connect ${SERVER_NAME}:443" 1>&2
    fi
}

Courier_mta()
{
    test -z "$COURIER_COMBINED" && return 125
    test -z "$COURIER_DHPARAMS" && return 125

    test -d "$(dirname "$COURIER_COMBINED")" || Die 20 "courier ssl dir"

    # shellcheck disable=SC1091
    COURIER_USER="$(source /etc/courier/esmtpd >/dev/null; echo "$MAILUSER")"

    echo "Installing Courier MTA certificate ..."
    # Private + public + intermediate
    cat "$PRIV" "$PUB" "$INT" >"$COURIER_COMBINED" || Die 21 "courier cert creation"

    # As in courier-mta/postinst
    # NOTICE Synchronize with monit/services/courier-mta
    chown "${COURIER_USER}:root" "$COURIER_COMBINED" || Die 22 "courier owner"
    chmod 0600 "$COURIER_COMBINED" || Die 23 "courier perms"
    # IMAP certificate
    if [ -n "$COURIER_IMAP_COMBINED" ]; then
        cp "$COURIER_COMBINED" "$COURIER_IMAP_COMBINED" || Die 27 "courier IMAP cert copy"
    fi

    nice openssl dhparam 2048 >"$COURIER_DHPARAMS" || Die 24 "courier DH params"
    # As in /usr/sbin/mkdhparams
    # NOTICE Synchronize with monit/services/courier-mta
    chown "${COURIER_USER}:root" "$COURIER_DHPARAMS" || Die 25 "courier DH params owner"
    chmod 0600 "$COURIER_DHPARAMS" || Die 26 "courier DH params perms"

    # Reload monit
    if [ "$(dpkg-query --showformat='${Status}' --show monit 2>/dev/null)" == "install ok installed" ]; then
        service monit reload
    fi

    SERVER_NAME="$(head -n 1 /etc/courier/me)"

    # Check config files for SMTP STARTTLS and outgoing SMTP
    if ! grep -q -F -x 'ADDRESS=127.0.0.1' /etc/courier/esmtpd; then
        if grep -q -x "TLS_CERTFILE=${COURIER_COMBINED}" /etc/courier/esmtpd \
            && grep -q -x "TLS_DHPARAMS=${COURIER_DHPARAMS}" /etc/courier/esmtpd; then

            service courier-mta restart

            # Test SMTP STARTTLS
            echo QUIT | openssl s_client -CAfile "$CABUNDLE" -crlf \
                -servername "$SERVER_NAME" -connect "${SERVER_NAME}:25" -starttls smtp
            echo "SMTP STARTTLS result=$?"
            echo QUIT | openssl s_client -CAfile "$CABUNDLE" -crlf \
                -servername "$SERVER_NAME" -connect "${SERVER_NAME}:25" -starttls smtp 2>/dev/null \
                | openssl x509 -noout -dates
        else
            echo "Add 'TLS_CERTFILE=${COURIER_COMBINED}' to courier config: esmtpd" 1>&2
            echo "echo QUIT|openssl s_client -CAfile ${CABUNDLE} -crlf -servername ${SERVER_NAME} -connect ${SERVER_NAME}:25 -starttls smtp" 1>&2
        fi
    fi

    # Check config files for submission (MSA)
    if grep -q -F -x 'ESMTPDSTART=YES' /etc/courier/esmtpd-msa; then
        if grep -q -x "TLS_CERTFILE=${COURIER_COMBINED}" /etc/courier/esmtpd \
            && grep -q -x "TLS_DHPARAMS=${COURIER_DHPARAMS}" /etc/courier/esmtpd; then

            service courier-msa restart

            # Test SMTP-MSA STARTTLS
            echo QUIT | openssl s_client -CAfile "$CABUNDLE" -crlf \
                -servername "$SERVER_NAME" -connect "${SERVER_NAME}:587" -starttls smtp
            echo "SMTPS-MSA result=$?"
        else
            echo "Add 'TLS_CERTFILE=${COURIER_COMBINED}' to courier config: esmtpd-msa" 1>&2
            echo "echo QUIT|openssl s_client -CAfile ${CABUNDLE} -crlf -servername ${SERVER_NAME} -connect ${SERVER_NAME}:587 -starttls smtp" 1>&2
        fi
    fi

    # Check config file for IMAPS
    if [ -f /etc/courier/imapd-ssl ]; then
        if grep -q -x "TLS_CERTFILE=${COURIER_COMBINED}" /etc/courier/imapd-ssl \
            && grep -q -x "TLS_DHPARAMS=${COURIER_DHPARAMS}" /etc/courier/imapd-ssl; then

            service courier-imap-ssl restart

            # Test IMAPS
            echo QUIT | openssl s_client -CAfile "$CABUNDLE" -crlf \
                -servername "$SERVER_NAME" -connect "${SERVER_NAME}:993"
            echo "IMAPS result=$?"
        else
            echo "Add 'TLS_CERTFILE=${COURIER_COMBINED}' to courier config imapd-ssl" 1>&2
            echo "echo QUIT|openssl s_client -CAfile ${CABUNDLE} -crlf -servername ${SERVER_NAME} -connect ${SERVER_NAME}:993" 1>&2
        fi
    fi

    echo "$(tput setaf 3;tput bold)WARNING: Update msmtprc:tls_fingerprint on SMTP clients.$(tput sgr0)"
}

Nginx()
{
    [ -z "$NGINX_PUB" ] && return 125
    [ -z "$NGINX_DHPARAM" ] && return 125
    [ -z "$NGINX_PRIV" ] && return 125
    [ -z "$NGINX_VHOST_CONFIG" ] && return 125

    [ -d "$(dirname "$NGINX_PUB")" ] || Die 70 "nginx ssl dir"

    echo "Installing Nginx certificate ..."
    cat "$PUB" "$INT" >"$NGINX_PUB" || Die 71 "nginx cert creation"
    nice openssl dhparam 2048 >"$NGINX_DHPARAM" || Die 72 "nginx private"
    cp "$PRIV" "$NGINX_PRIV" || Die 73 "nginx private"
    chown root:root "$NGINX_PUB" "$NGINX_PRIV" || Die 74 "nginx owner"
    chmod 0640 "$NGINX_PUB" "$NGINX_PRIV" || Die 75 "nginx perms"

    # Check config
    if  grep -q "^\\s*ssl_certificate\\s\\+${NGINX_PUB}\$" "$NGINX_VHOST_CONFIG" \
        && grep -q "^\\s*ssl_certificate_key\\s\\+${NGINX_PRIV}\$" "$NGINX_VHOST_CONFIG" \
        && grep -q "^\\s*ssl_dhparam\\s\\+${NGINX_DHPARAM}\$" "$NGINX_VHOST_CONFIG"; then

        nginx -t && service nginx restart

        # Test HTTPS
        SERVER_NAME="$(sed -ne '/^\s*server_name\s\+\(\S\+\);.*$/{s//\1/p;q;}' "$NGINX_VHOST_CONFIG")"
        echo -n | openssl s_client -CAfile "$CABUNDLE" -servername "$SERVER_NAME" -connect "${SERVER_NAME}:443"
        echo "HTTPS result=$?"
    else
        echo "Edit Nginx ssl_certificate and ssl_certificate_key and ssl_dhparam" 1>&2
    fi
}

Proftpd()
{
    [ -z "$PROFTPD_PUB" ] && return 125
    [ -z "$PROFTPD_PRIV" ] && return 125
    [ -z "$PROFTPD_INT" ] && return 125

    [ -d "$(dirname "$APACHE_PUB")" ] || Die 30 "proftpd ssl dir"

    echo "Installing Proftpd certificate ..."
    cp "$PUB" "$PROFTPD_PUB" || Die 31 "proftpd public"
    cp "$PRIV" "$PROFTPD_PRIV" || Die 32 "proftpd private"
    cp "$INT" "$PROFTPD_INT" || Die 33 "proftpd intermediate"
    chown root:root "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPD_INT" || Die 34 "proftpd owner"
    chmod 0600 "$PROFTPD_PUB" "$PROFTPD_PRIV" "$PROFTPD_INT" || Die 35 "proftpd perms"

    # Check config
    if  grep -q "^TLSRSACertificateFile\\s*${PROFTPD_PUB}\$" /etc/proftpd/tls.conf \
        && grep -q "^TLSRSACertificateKeyFile\\s*${PROFTPD_PRIV}\$" /etc/proftpd/tls.conf \
        && grep -q "^TLSCACertificateFile\\s*${PROFTPD_INT}\$" /etc/proftpd/tls.conf; then

        service proftpd restart

        # Test FTP
        echo "QUIT" | openssl s_client -crlf -CAfile "$CABUNDLE" \
            -servername "$SERVER_NAME" -connect localhost:21 -starttls ftp
        echo "AUTH TLS result=$?"
    else
        echo "Edit ProFTPd TLSRSACertificateFile, TLSRSACertificateKeyFile and TLSCACertificateFile" 1>&2
    fi
}

Dovecot()
{
    [ -z "$DOVECOT_PUB" ] && return 125
    [ -z "$DOVECOT_PRIV" ] && return 125

    [ -d "$(dirname "$DOVECOT_PUB")" ] || Die 50 "dovecot ssl dir"

    echo "Installing Dovecot certificate ..."
    # Dovecot: public + intermediate
    cat "$PUB" "$INT" >"$DOVECOT_PUB" || Die 51 "dovecot cert creation"
    cat "$PRIV" >"$DOVECOT_PRIV" || Die 52 "dovecot private cert creation"
    chown root:root "$DOVECOT_PUB" "$DOVECOT_PRIV" || Die 53 "dovecot owner"
    chmod 0600 "$DOVECOT_PUB" "$DOVECOT_PRIV" || Die 54 "dovecot perms"

    # Check config files for ssl_cert, ssl_key
    if grep -q "^ssl_cert\\s*=\\s*<${DOVECOT_PUB}\$" /etc/dovecot/conf.d/10-ssl.conf \
        && grep -q "^ssl_key\\s*=\\s*<${DOVECOT_PRIV}\$" /etc/dovecot/conf.d/10-ssl.conf; then

        service dovecot restart

        # Tests POP3, POP3S, IMAP, IMAPS
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
        echo "Edit Dovecot ssl_cert and ssl_key" 1>&2
    fi
}

Webmin()
{
    [ -z "$WEBMIN_COMBINED" ] && return 125
# @FIXME Could be a separate public key: "certfile="
    [ -z "$WEBMIN_INT" ] && return 125

    [ -d "$(dirname "$WEBMIN_COMBINED")" ] || Die 60 "webmin ssl dir"

    echo "Installing Webmin certificate ..."
    # Webmin: private + public
    cat "$PRIV" "$PUB" >"$WEBMIN_COMBINED" || Die 61 "webmin public"
    cp "$INT" "$WEBMIN_INT" || Die 62 "webmin intermediate"
    chown root:root "$WEBMIN_COMBINED" "$WEBMIN_INT" || Die 63 "webmin owner"
    chmod 0600 "$WEBMIN_COMBINED" "$WEBMIN_INT" || Die 64 "webmin perms"

    # Check config
    if  grep -q "^keyfile=${WEBMIN_COMBINED}\$" /etc/webmin/miniserv.conf \
        && grep -q "^extracas=${WEBMIN_INT}\$" /etc/webmin/miniserv.conf; then

        service webmin restart

        # Test HTTPS:10000
        echo -n | timeout 3 openssl s_client -CAfile "$CABUNDLE" -crlf -connect localhost:10000
        echo "HTTPS result=$?"
    else
        echo "Edit Webmin keyfile and extracas" 1>&2
    fi
}

Check_requirements
Protect_certs

Apache2 && Readkey

Courier_mta && Readkey

Nginx && Readkey

Proftpd && Readkey

Dovecot && Readkey

Webmin && Readkey

echo "OK."
