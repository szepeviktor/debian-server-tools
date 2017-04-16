#!/bin/bash
#
# Check SSL secured services.
#
# VERSION       :0.1.1
# DATE          :2017-03-28
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/ssl-check.sh
# CRON-DAILY    :/usr/local/bin/ssl-check.sh

# Configuration syntax
#
#     SSL_CHECK=(
#       HOSTNAME:PORT[:STARTTLS]
#       szepe.net:587:smtp
#       szepe.net:465
#     )

DAEMON="ssl-check"
SSL_CHECK_RC="/etc/sslcheckrc"

# Defaults
declare -a SSL_CHECK

Remove_known_ssl_values() {
    grep -vFx "issuer=/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3" \
    | grep -vFx "issuer=/C=GB/ST=Greater Manchester/L=Salford/O=COMODO CA Limited/CN=COMODO RSA Domain Validation Secure Server CA" \
    | grep -vFx "Server public key is 2048 bit" \
    | grep -vFx "Secure Renegotiation IS supported" \
    | grep -vFx "    Protocol  : TLSv1.2" \
    | grep -vFx "    Cipher    : ECDHE-RSA-AES128-GCM-SHA256" \
    | grep -vFx "    Cipher    : ECDHE-RSA-AES256-GCM-SHA384" \
    # Keeping last backslash inactive
}

set -e

# shellcheck disable=SC1090
source "$SSL_CHECK_RC"

# Check hosts
for SERVICE in "${SSL_CHECK[@]}"; do
    HOST="$(cut -d ":" -f 1 <<< "$SERVICE")"
    PORT="$(cut -d ":" -f 2 <<< "$SERVICE")"
    STARTTLS="$(cut -d ":" -f 3 <<< "$SERVICE")"
    SSL_ARGS=""

    # Optional STARTTLS
    if [ -n "$STARTTLS" ]; then
        SSL_ARGS="-starttls ${STARTTLS}"
    fi

    # Support SNI
    # shellcheck disable=SC2086
    SSL_OUTPUT="$(timeout 40 openssl s_client -purpose "sslserver" -verify_return_error \
        -connect "${HOST}:${PORT}" -servername "$HOST" ${SSL_ARGS} \
        < /dev/null 2> /dev/null \
        | grep -E "^(issuer=|Server public key is|Secure Renegotiation|    Protocol  :|    Cipher    :|    Verify return code:)" \
        | Remove_known_ssl_values)"
    if [ "$SSL_OUTPUT" != "    Verify return code: 0 (ok)" ]; then
        echo "${DAEMON}: Unexpected output for ${SERVICE}" 1>&2
    fi
done

exit 0
