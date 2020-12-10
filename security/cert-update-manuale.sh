#!/bin/bash
#
# Issue or renew certificate by automatoes and cert-update.sh
#
# VERSION       :0.3.0
# DATE          :2020-02-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :/usr/local/sbin/cert-update.sh
# LOCATION      :/usr/local/sbin/cert-update-manuale.sh

# automatoes installation
#     python-add-opt-package.sh automatoes manuale
#
# Register a new account
#     manuale register EMAIL
#
# Create a skeleton configuration file
#     cert-update-manuale.sh -dump example.com.conf
#
# Private: CERTIFICATE-NAME.pem
# Cert:    CERTIFICATE-NAME.crt
# Int:     CERTIFICATE-NAME.intermediate.crt
# Chain:   CERTIFICATE-NAME.chain.crt

# Common variables
# Variables for cert-update.sh
CABUNDLE="/etc/ssl/certs/ca-certificates.crt"
PRIV_DIR="/etc/ssl/private"
PUB_DIR="/etc/ssl/localcerts"

Dump_configuration()
{
    local CONFIG_FILE="$1"

    cat >"$CONFIG_FILE" <<"EOF"
#!/usr/local/sbin/cert-update-manuale.sh
# Configuration for cert-update-manuale.sh

#source /home/USER/manuale-env/bin/activate
#MANUALE_PATH=/home/USER/manuale-env/bin/manuale

#EC_KEY=YES

AUTHORIZATION=DNS
#AUTHORIZATION=HTTP
#CHALLENGE_PATH="/home/USER/website/code/.well-known/acme-challenge"

COMMON_NAME="example.com"
# Additional domain names into SAN extension (Subject Alternative Name)
DOMAIN_NAMES="www.example.com app.example.com"

APACHE_ENABLED=YES
APACHE_DOMAIN=COMMON-NAME
#APACHE_DOMAIN=SAN-FIRST
#APACHE_DOMAIN=SAN-LAST
#APACHE_DOMAIN="www.example.com"
APACHE_VHOST_CONFIG=DOMAIN
#APACHE_VHOST_CONFIG="/etc/apache2/sites-available/custom-example.com.conf"

#COURIER_ENABLED=YES

#NGINX_ENABLED=YES
NGINX_DOMAIN=COMMON-NAME
#NGINX_DOMAIN=SAN-FIRST
#NGINX_DOMAIN=SAN-LAST
#NGINX_DOMAIN="www.example.com"
NGINX_VHOST_CONFIG=DOMAIN
#NGINX_VHOST_CONFIG="/etc/apache2/sites-available/custom-example.com.conf"

#DOVECOT_ENABLED=YES

#PROFTPD_ENABLED=YES

#WEBMIN_ENABLED=YES
EOF

    chmod +x "$CONFIG_FILE"
}

Manuale()
{
    # shellcheck disable=SC2016
    if [ -n "$MANUALE_PATH" ]; then
        # Custom path
        u "$MANUALE_PATH" "$@"
    elif u bash -c -- 'test -x "${HOME}/.local/bin/manuale"'; then
        # The Python user install directory
        u bash -c -- '"${HOME}/.local/bin/manuale" "$@"' manuale "$@"
    elif u bash -c -- 'test -x "${HOME}/bin/manuale"'; then
        # User bin directory
        u bash -c -- '"${HOME}/bin/manuale" "$@"' manuale "$@"
    elif u bash -c -- "hash manuale"; then
        # System-wide installation (/usr/bin/, /usr/local/bin/ etc.)
        u bash -c -- 'manuale "$@"' manuale "$@"
    else
        echo "manuale command not found." 1>&2
        exit 127
    fi
}

Move_challenge_files()
{
    local WELL_KNOWN_ACME_CHALLENGE="$1"

    if [ ! -d "$WELL_KNOWN_ACME_CHALLENGE" ]; then
        echo "Missing .well-known/acme-challenge directory: '${WELL_KNOWN_ACME_CHALLENGE}'" 1>&2
        exit 10
    fi

    echo "Waiting 5 seconds for each challenge file ..."
    for _ in ${COMMON_NAME} ${DOMAIN_NAMES}; do
        sleep 5
    done

    find . -maxdepth 1 -type f -mmin -3 -regextype posix-egrep -regex '\./[0-9A-Za-z_-]{43}' -print0 \
        | xargs -r -0 -I % cp -v % "${WELL_KNOWN_ACME_CHALLENGE}/"

    # Wait for authorization
    sleep 60
    echo
    rm -v "${WELL_KNOWN_ACME_CHALLENGE}"/*
}

set -e

CONFIGURATION="$1"

# Dump skeleton configuration
if  [ "$CONFIGURATION" == -dump ]; then
    if [ "$#" == 2 ]; then
        Dump_configuration "$2"
    else
        Dump_configuration "example.conf"
    fi
    exit 0
fi

# Check user
if [[ $EUID -ne 0 ]]; then
    echo "You need to be root." 1>&2
    exit 124
fi

# Verify CA bundle
openssl verify "$CABUNDLE"

# Check configuration file
if [ ! -r "$CONFIGURATION" ]; then
    echo "Please provide a configuration file" 1>&2
    exit 125
fi

# shellcheck disable=SC1090
source "$CONFIGURATION"

# Check account file
if [ ! -r ./account.json ]; then
    echo "Please run:  manuale register EMAIL" 1>&2
    exit 125
fi
Manuale info

# Check domain names
if [ -z "${COMMON_NAME+x}" ] || [ -z "$COMMON_NAME" ] || [ -z "${DOMAIN_NAMES+x}" ]; then
    echo "Please set COMMON_NAME and DOMAIN_NAMES even if empty" 1>&2
    exit 125
fi

# Variables for cert-update.sh
# Private key file name
PRIV="${COMMON_NAME}.pem"
# Public key file name, the signed certificate
PUB="${COMMON_NAME}.crt"
# Intermediate certificate file name
INT="${COMMON_NAME}.intermediate.crt"

# Certificate Authority Authorization
if [ "${COMMON_NAME:0:1}" == "*" ]; then
    echo "${COMMON_NAME}.  IN  CAA  0 issue \";\""
    echo "${COMMON_NAME}.  IN  CAA  0 issuewild \"letsencrypt.org\""
else
    echo "${COMMON_NAME}.  IN  CAA  0 issue \"letsencrypt.org\""
    echo "${COMMON_NAME}.  IN  CAA  0 issuewild \";\""
fi
echo "${COMMON_NAME}.  IN  CAA  0 iodef \"mailto:admin@szepe.net\""

# Generate TLSA Record
# Usage:         0 - PKIX-TA: Certificate Authority Constraint
# Selector:      1 - SPKI: Subject Public Key
# Matching Type: 2 - SHA-512: SHA-512 Hash
printf '_443._tcp.%s.  IN  TLSA  0 1 2 ' "$COMMON_NAME"
openssl x509 -noout -pubkey -in "$INT" \
    | openssl rsa -pubin -outform DER | openssl sha512 | cut -d " " -f 2 | tr "[:lower:]" "[:upper:]"

# Authorize or check authorization
if [ "$AUTHORIZATION" == HTTP ]; then
    Move_challenge_files "$CHALLENGE_PATH" &
    # shellcheck disable=SC2086
    Manuale authorize --method http "$COMMON_NAME" ${DOMAIN_NAMES}
else
    # DNS-based authorization
    # shellcheck disable=SC2086
    Manuale authorize "$COMMON_NAME" ${DOMAIN_NAMES}
fi

# Issue certificate
if [ "$EC_KEY" == YES ]; then
    # The faster NIST curve
    u openssl ecparam -out "${COMMON_NAME}-param.pem" -name prime256v1 -genkey
    # shellcheck disable=SC2086
    Manuale issue --key-file "${COMMON_NAME}-param.pem" "$COMMON_NAME" ${DOMAIN_NAMES}
else
    # shellcheck disable=SC2086
    Manuale issue "$COMMON_NAME" ${DOMAIN_NAMES}
fi

# Verify private key
openssl pkey -in "$PRIV" -noout
# Verify signature
openssl verify -purpose sslserver -CAfile "$INT" "$PUB"

# Display certificate data
printf 'CN        = '; openssl x509 -in "$PUB" -noout -subject|sed -ne 's|^.*[/=]CN \?= \?\([^/]\+\).*$|\1|p'
printf 'SAN-FIRST = '; openssl x509 -in "$PUB" -noout -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^\s*DNS:\(\S\+\), .*$/\1/p}'
printf 'SAN-LAST  = '; openssl x509 -in "$PUB" -noout -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}'

# Start certificate installations

if [ "$APACHE_ENABLED" == YES ]; then
    case "$APACHE_DOMAIN" in
        COMMON-NAME)
            # Use Common Name
            APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's|^.*[/=]CN \?= \?\([^/]\+\).*$|\1|p')"
            ;;
        SAN-LAST)
            # Use last Subject Alternative Name
            APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^.*DNS://p}')"
            ;;
        SAN-FIRST)
            # Use first Subject Alternative Name
            APACHE_DOMAIN="$(openssl x509 -in "$PUB" -noout -text|sed -ne '/^\s*X509v3 Subject Alternative Name:/{n;s/^\s*DNS:\(\S\+\), .*$/\1/p}')"
            ;;
        *)
            # Custom domain name
            if [ "$APACHE_DOMAIN" == "${APACHE_DOMAIN/./}" ]; then
                echo "Apache domain name is not valid (${APACHE_DOMAIN})" 1>&2
                exit 10
            fi
            ;;
    esac

    # Replace wildcard prefix in domain name
    APACHE_DOMAIN="${APACHE_DOMAIN/\*./wildcard.}"

    # Use domain name in host config file name
    if [ "$APACHE_VHOST_CONFIG" == DOMAIN ]; then
        APACHE_VHOST_CONFIG="/etc/apache2/sites-available/${APACHE_DOMAIN}.conf"
    fi

    # Custom host config file name
    if [ ! -r "${APACHE_VHOST_CONFIG%.conf}.conf" ]; then
        echo "Apache host config file not found (${APACHE_VHOST_CONFIG})" 1>&2
        exit 11
    fi

    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    APACHE_PUB="${PUB_DIR}/${APACHE_DOMAIN}-public.pem"
    # shellcheck disable=SC2034
    APACHE_PRIV="${PRIV_DIR}/${APACHE_DOMAIN}-private.key"
fi

if [ "$COURIER_ENABLED" == YES ]; then
    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    COURIER_COMBINED="/etc/courier/esmtpd.pem"
    # shellcheck disable=SC2034
    COURIER_DHPARAMS="/etc/courier/dhparams.pem"
    # shellcheck disable=SC2034
    COURIER_IMAP_COMBINED="/etc/courier/imapd.pem"
fi

if [ "$NGINX_ENABLED" == YES ]; then
    # Use Common Name
    NGINX_DOMAIN="$(openssl x509 -in "$PUB" -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')"

    # Replace wildcard prefix
    NGINX_DOMAIN="${NGINX_DOMAIN/\*./wildcard.}"

    if [ "$NGINX_VHOST_CONFIG" == domain ]; then
        NGINX_VHOST_CONFIG="$NGINX_DOMAIN"
    fi

    # Custom host config file name
    if [ ! -r "/etc/nginx/sites-available/${NGINX_VHOST_CONFIG%.conf}.conf" ]; then
        echo "Nginx host config file not found (${NGINX_VHOST_CONFIG})" 1>&2
        exit 11
    fi

    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    NGINX_PUB="${PUB_DIR}/${NGINX_DOMAIN}-public.pem"
    # shellcheck disable=SC2034
    NGINX_DHPARAM="${PRIV_DIR}/${NGINX_DOMAIN}-dhparam.pem"
    # shellcheck disable=SC2034
    NGINX_PRIV="${PRIV_DIR}/${NGINX_DOMAIN}-private.key"
fi

if [ "$DOVECOT_ENABLED" == YES ]; then
    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    DOVECOT_PUB="/etc/dovecot/dovecot.pem"
    # shellcheck disable=SC2034
    DOVECOT_PRIV="/etc/dovecot/private/dovecot.key"
fi

if [ "$PROFTPD_ENABLED" == YES ]; then
    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    PROFTPD_PUB="/etc/proftpd/ssl-pub.pem"
    # shellcheck disable=SC2034
    PROFTPD_PRIV="/etc/proftpd/ssl-priv.key"
    # shellcheck disable=SC2034
    PROFTPD_INT="/etc/proftpd/sub.class1.server.ca.pem"
fi

if [ "$WEBMIN_ENABLED" == YES ]; then
    # SSL check on non-HTTPS ports: https://www.digicert.com/help/

    # Variables for cert-update.sh
    # shellcheck disable=SC2034
    WEBMIN_COMBINED="/etc/webmin/miniserv.pem"
    # shellcheck disable=SC2034
    WEBMIN_INT="/etc/webmin/sub.class1.server.ca.pem"
fi

# Execute cert-update
# shellcheck disable=SC1091
source /usr/local/sbin/cert-update.sh
