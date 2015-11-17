#!/bin/bash
#
# Check certificate expiry.
#
# VERSION       :0.3.0
# DATE          :2015-11-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl
# LOCATION      :/usr/local/bin/cert-expiry.sh
# CRON-WEEKLY   :/usr/local/bin/cert-expiry.sh

# Alert 10 days before expiration
ALERT_DAYS="10"

NOW_SEC="$(date "+%s")"

# Find all certificates in /etc/ excluding /etc/ssl/certs/
find /etc/ -not -path "/etc/ssl/certs/*" "(" -iname "*.crt" -or -iname "*.pem" ")" \
    | while read -r CERT; do
        # Not an X509 cert
        if ! grep -q -- "-BEGIN CERTIFICATE-" "$CERT"; then
            continue
        fi

        EXPIRY_DATE="$(openssl x509 -in "$CERT" -noout -enddate | cut -d "=" -f 2-)"
        EXPIRY_SEC="$(date --date "$EXPIRY_DATE" "+%s")"

        if [ $? != 0 ]; then
            echo "Invalid end date (${EXPIRY_DATE}) in ${CERT}" 1>&2
            continue
        fi

        EXPIRY_DAYS="$(( (EXPIRY_SEC - NOW_SEC) / 86400 ))"
        #echo -e "[DBG] file: ${CERT} / days: ${EXPIRY_DAYS}" 1>&2

        if [ "$EXPIRY_DAYS" -lt "$ALERT_DAYS" ]; then
            # Alert
            CERT_SUBJECT="$(openssl x509 -in "$CERT" -noout -subject | cut -d "=" -f 2-)"
            echo "${CERT_SUBJECT} (${CERT}) expires in ${EXPIRY_DAYS} day(s)."
        fi
    done

exit 0
