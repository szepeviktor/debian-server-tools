#!/bin/sh
#
# Display OCSP response.
#

# StartSSL Class 1 DV SSL certificate
STARTSSL_CA_URL_CLASS1="https://www.startssl.com/certs/sca.server1.crt"
STARTSSL_CA_CLASS1="./sca.server1.crt.pem"
STARTSSL_OCSP_URL_CLASS1="http://ocsp.startssl.com/sub/class1/server/ca"
STARTSSL_OCSP_HOST="ocsp.startssl.com"

CERT="$1"

[ -f "$CERT" ] || exit 1

if ! [ -r "$STARTSSL_CA_CLASS1" ]; then
    wget -nv -O "$STARTSSL_CA_CLASS1" "$STARTSSL_CA_URL_CLASS1"
fi

openssl ocsp -no_nonce \
    -CAfile "$STARTSSL_CA_CLASS1" -issuer "$STARTSSL_CA_CLASS1" \
    -header "Host" "$STARTSSL_OCSP_HOST" -url "$STARTSSL_OCSP_URL_CLASS1" \
    -cert "$CERT"
