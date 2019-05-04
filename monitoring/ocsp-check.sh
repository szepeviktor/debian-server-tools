#!/bin/bash
#
# Display OCSP response.
#
# VERSION       :2.5.5
# DATE          :2019-05-04
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl
# UPSTREAM      :https://github.com/matteocorti/check_ssl_cert
# LOCATION      :/usr/local/bin/ocsp-check.sh

# Usage
#
#     editor /usr/local/bin/ocsp--SITE.sh
#         #!/bin/bash
#         exec 200<$0; flock --nonblock 200 || exit 0
#         while ! timeout 10 /usr/local/bin/ocsp-check.sh "www.example.com" >/dev/null;do sleep 30;done;exit 0
#     chmod +x /usr/local/bin/ocsp--SITE.sh
#     echo -e "05,35 *  * * * nobody\t/usr/local/bin/ocsp--SITE.sh" >/etc/cron.d/ocsp-SITE-NO-DOTS

HOST="$1"

Onexit()
{
    local -i RET="$1"
    local BASH_CMD="$2"

    set +e

    # Cleanup
    rm -f "$CERTIFICATE" "$CA_ISSUER_CERT" "$CA_ISSUER_CERT_PEM" &>/dev/null

    if [ "$RET" -ne 0 ]; then
        echo "$(date "+%b %e %T") COMMAND WITH ERROR: ${BASH_CMD}" 1>&2
    fi

    exit "$RET"
}

set -e

declare -i THIS_UPDATE_SECOND
declare -i NEXT_UPDATE_SECOND

trap 'Onexit "$?" "$BASH_COMMAND"' EXIT HUP INT QUIT PIPE TERM

test -n "$HOST"

CERTIFICATE="$(mktemp -t "${0##*/}.XXXXXXXX")"
CA_ISSUER_CERT="$(mktemp -t "${0##*/}.XXXXXXXX")"
CA_ISSUER_CERT_PEM="$(mktemp -t "${0##*/}.XXXXXXXX")"

# Get certificate
openssl s_client -connect "${HOST}:443" -servername "$HOST" </dev/null >"$CERTIFICATE" 2>/dev/null

# First OCSP URI
OCSP_URI="$(openssl x509 -in "$CERTIFICATE" -noout -ocsp_uri | head -n 1)"
test -n "$OCSP_URI"

OCSP_HOST="$(sed -e 's;^.*//\([^/]\+\)\(/.*\)\?$;\1;' <<<"$OCSP_URI")"
test -n "$OCSP_HOST"

# First issuer certificate
CA_ISSUER_CERT_URI="$(openssl x509 -in "${CERTIFICATE}" -text -noout \
    | sed -n -e '/^\s*Authority Information Access:\s*$/,/^\s*$/s/^\s*CA Issuers - URI:\(.\+\)$/\1/p' \
    | head -n 1)"
test -n "$CA_ISSUER_CERT_URI"

# Download issuer certificate
wget -q -t 1 -O "$CA_ISSUER_CERT" "$CA_ISSUER_CERT_URI"
# Convert DER to PEM
if openssl x509 -inform DER -in "$CA_ISSUER_CERT" -noout 2>/dev/null; then
    openssl x509 -inform DER -in "$CA_ISSUER_CERT" -outform PEM -out "$CA_ISSUER_CERT_PEM"
    cp -f "$CA_ISSUER_CERT_PEM" "$CA_ISSUER_CERT"
fi
# Issuer certificate validity
openssl x509 -inform PEM -in "$CA_ISSUER_CERT" -noout
# Verify whether certificate is signed by issuer
openssl verify -purpose "sslserver" -CAfile "$CA_ISSUER_CERT" "$CERTIFICATE" \
    | grep -qFx "${CERTIFICATE}: OK"

# Get OCSP response
# https://community.letsencrypt.org/t/unable-to-verify-ocsp-response/7264/5
# Syntax changed in 1.1.0: from `-header Host $host` to `-header Host=$host`
if openssl version | grep -qFi "openssl 1.0."; then
    HOST_SEPARATOR=" "
else
    HOST_SEPARATOR="="
fi
# shellcheck disable=SC2086
OCSP_RESPONSE="$(openssl ocsp -no_nonce -timeout 10 \
    -CAfile "$CA_ISSUER_CERT" -issuer "$CA_ISSUER_CERT" -verify_other "$CA_ISSUER_CERT" \
    -cert "$CERTIFICATE" \
    -header Host${HOST_SEPARATOR}${OCSP_HOST} -url "$OCSP_URI" 2>&1)"
if ! grep -qFx "Response verify OK" <<<"$OCSP_RESPONSE"; then
    echo "Invalid OCSP response" 1>&2
    exit 101
fi
if ! grep -qFx "${CERTIFICATE}: good" <<<"$OCSP_RESPONSE"; then
    echo "Certificate may be revoked: ${OCSP_RESPONSE}" 1>&2
    exit 102
fi

# Check update dates
THIS_UPDATE="$(sed -n -e '0,/^\s*This Update: \(.\+\)$/s//\1/p' <<<"$OCSP_RESPONSE")"
NEXT_UPDATE="$(sed -n -e '0,/^\s*Next Update: \(.\+\)$/s//\1/p' <<<"$OCSP_RESPONSE")"
test -n "$THIS_UPDATE"
test -n "$NEXT_UPDATE"

# Check expiry
THIS_UPDATE_SECOND="$(date --date "$THIS_UPDATE" "+%s")"
NEXT_UPDATE_SECOND="$(date --date "$NEXT_UPDATE" "+%s")"
test "$NEXT_UPDATE_SECOND" -ge "$(date "+%s")"

# Check expiration time
declare -i OCSP_HOURS="$(( ( NEXT_UPDATE_SECOND - THIS_UPDATE_SECOND ) / 3600 ))"
test "$OCSP_HOURS" -ge 24
test "$OCSP_HOURS" -le 240

# OK message
echo "${HOST} OCSP period: ${OCSP_HOURS} hours"

exit 0
