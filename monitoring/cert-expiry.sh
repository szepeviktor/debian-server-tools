#!/bin/bash
#
# Check certificate expiry.
#
# VERSION       :0.4.1
# DATE          :2016-04-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl ca-certificates
# LOCATION      :/usr/local/sbin/cert-expiry.sh
# CRON-WEEKLY   :/usr/local/sbin/cert-expiry.sh
# CONFIG        :~/.config/certexpiry/configuration

# @TODO Add support for starttls: HOST:PORT:smtp HOST:PORT:imap

# Alert 10 days before expiration
ALERT_DAYS="10"

NOW_SEC="$(date "+%s")"
CERT_EXPIRY_CONFIG="${HOME}/.config/certexpiry/configuration"

Check_cert() {
    local CERT="$1"

    # Not an X509 formatted certificate
    if ! grep -q -- "-BEGIN CERTIFICATE-" "$CERT"; then
        return 1
    fi

    EXPIRY_DATE="$(openssl x509 -in "$CERT" -noout -enddate | cut -d "=" -f 2-)"
    EXPIRY_SEC="$(date --date "$EXPIRY_DATE" "+%s")"

    if [ $? != 0 ]; then
        echo "Invalid end date (${EXPIRY_DATE}) in ${CERT}" 1>&2
        return 2
    fi

    EXPIRY_DAYS="$(( (EXPIRY_SEC - NOW_SEC) / 86400 ))"
    #echo -e "[DBG] file: ${CERT} days: ${EXPIRY_DAYS}" 1>&2

    # Alert
    if [ "$EXPIRY_DAYS" -le "$ALERT_DAYS" ]; then
        CERT_SUBJECT="$(openssl x509 -in "$CERT" -noout -subject | cut -d "=" -f 2-)"
        echo "${CERT_SUBJECT} (${CERT}) expires in ${EXPIRY_DAYS} day(s)." 2>&1
        return 3
    fi
}

if [ -r "$CERT_EXPIRY_CONFIG" ]; then
    # CERT_EXPIRY_REMOTES=( host:port )
    source "$CERT_EXPIRY_CONFIG"
fi

# Certificates in /etc/ excluding /etc/ssl/certs/
find /etc/ -not -path "/etc/ssl/certs/*" -not -path "/etc/letsencrypt/archive/*" \
    "(" -iname "*.crt" -or -iname "*.pem" ")" \
    | while read -r CERT; do
        Check_cert "$CERT"
    done

# Remote certificates
if [ -n "${CERT_EXPIRY_REMOTES[*]}" ]; then
    for HOST_PORT in "${CERT_EXPIRY_REMOTES[@]}"; do
        # Set file name for expiry reporting
        CERT_EXPIRY_TMP="$(mktemp "/tmp/${HOST_PORT%%:*}-XXXXXXXXXX")"
        openssl s_client -CAfile /etc/ssl/certs/ca-certificates.crt -connect "$HOST_PORT" \
            < /dev/null 1> "$CERT_EXPIRY_TMP" 2> /dev/null
        Check_cert "$CERT_EXPIRY_TMP"
        rm -f "$CERT_EXPIRY_TMP"
    done
fi

exit 0
