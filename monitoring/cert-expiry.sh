#!/bin/bash
#
# Check certificate expiry.
#
# VERSION       :0.5.6
# DATE          :2018-02-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl ca-certificates
# LOCATION      :/usr/local/sbin/cert-expiry.sh
# CRON-WEEKLY   :/usr/local/sbin/cert-expiry.sh
# CONFIG        :/etc/certexpiry

# Configuration file
#
#     ALERT_DAYS="21"
#     CERT_EXPIRY_REMOTES=(
#         example.com:443
#     )

# @TODO Add support for starttls: HOST:PORT:smtp HOST:PORT:imap

# Alert 10 days before expiration
ALERT_DAYS="10"
CERT_EXPIRY_CONFIG="/etc/certexpiry"
declare -a CERT_EXPIRY_REMOTES

Check_cert()
{
    local CERT="$1"
    local -i END_SEC
    local END_CHECK
    local CERT_SUBJECT
    local EXPIRY_DATE

    # Not a base64 encoded certificate
    if ! grep -q -- "-BEGIN CERTIFICATE-" "$CERT"; then
        return
    fi

    END_SEC="$((ALERT_DAYS * 86400))"
    END_CHECK="$(openssl x509 -in "$CERT" -checkend "$END_SEC" || true)"

    # Alert
    if [ "$END_CHECK" != "Certificate will not expire" ]; then
        CERT_SUBJECT="$(openssl x509 -in "$CERT" -noout -subject | cut -d "=" -f 2-)"
        EXPIRY_DATE="$(openssl x509 -in "$CERT" -noout -enddate | cut -d "=" -f 2-)"
        echo "${CERT_SUBJECT} (${CERT}) expires at ${EXPIRY_DATE}"
    fi
}

set -e

if [ -r "$CERT_EXPIRY_CONFIG" ]; then
    # shellcheck disable=SC1090
    source "$CERT_EXPIRY_CONFIG"
fi

# Certificates in /etc/
find /etc/ "(" -iname "*.crt" -or -iname "*.pem" ")" \
    -not -path "/etc/ssl/certs/*" \
    -not -path "/etc/letsencrypt/archive/*" \
    | while read -r CERT; do
        Check_cert "$CERT"
    done

# Remote certificates
for HOST_PORT in "${CERT_EXPIRY_REMOTES[@]}"; do
    # Set file name for expiry reporting
    CERT_EXPIRY_TMP="$(mktemp "/tmp/${HOST_PORT%%:*}-XXXXX")"

    if openssl s_client -CAfile /etc/ssl/certs/ca-certificates.crt \
        -connect "$HOST_PORT" -servername "${HOST_PORT%%:*}" \
        </dev/null 1>"$CERT_EXPIRY_TMP" 2>/dev/null; then
        Check_cert "$CERT_EXPIRY_TMP"
    else
        echo "Certificate check error for ${HOST_PORT}" 1>&2
    fi

    rm "$CERT_EXPIRY_TMP"
done

exit 0
