#!/bin/bash

exit 0

# http://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml
IANA_URL="http://www.iana.org/assignments/tls-parameters/tls-parameters-4.csv"
# head -n 1 tls-parameters-4.csv | grep -o "," | wc -l
IANA_COLUMNS="3"
NSS_URL="https://raw.githubusercontent.com/jvehent/tlsnames/master/NSS_TLS_Names.csv"

Parse_csv() {
    local BUFFER
    local -i COLUMN="0"

    # Print first and second column separated with a colon
    Flush() {
        COLUMN+="1"
        [ "$COLUMN" -eq 1 ] && echo -n "${BUFFER}:"
        [ "$COLUMN" -eq 2 ] && echo "$BUFFER"
        BUFFER=""
    }

    while read -r STR; do

        if [ -z "$BUFFER" ]; then
            # empty buffer
            if [ "${STR:0:1}" == '"' ]; then
                # begin cell
                BUFFER="${STR:1}"
            else
                # no need to buffer
                BUFFER="$STR"
                Flush
            fi
        else
            # buffer not empty and no escaped quote
            if [ "${STR:(-1)}" == '"' ] && ! [ "${STR:(-2)}" == '\"' ]; then
                # end cell
                BUFFER+=",${STR:0:(-1)}"
                Flush
            else
                # collect more
                BUFFER+=",${STR}"
            fi
        fi

        [ "$COLUMN" -gt "$IANA_COLUMNS" ] && COLUMN="0"
    done
}

Get_iana() {
    # Get CSV
    #     Remove CR
    #     Convert newline into comma
    #     Parse
    #     Exclude non-ciphers
    wget -q -O- "$IANA_URL" \
        | tr -d $'\r' \
        | tr ',' $'\n' \
        | Parse_csv \
        | grep -i "^0x[0-9A-F]\{2\},0x[0-9A-F]\{2\}:" \
            > "iana-tls-cipher-suits.txt"
}

Parse_simple_csv() {
    # "SSL_CK_DES_192_EDE3_CBC_WITH_MD5,0x07"
    # "SSL_EN_RC4_128_WITH_MD5,0xFF01"
    return
}

Get_nss() {
    "$NSS_URL"
    return
}

# sqlite3 ?

# Steps
# input something IANA/OpenSSL/GnuTLS/NSS, name/hex, "003C" too
# output name -iana -openssl -gnutls -nss
# output hex -xiana -xopenssl -xgnutls -xnss

# check openssl, gnutls list output 2> /dev/null > 20

# cache all lists in a var

for orig in $(cat IANA_TLS_Names.csv); do
    hexval1=$(echo $orig|cut -d ',' -f1)
    hexval2=$(echo $orig|cut -d ',' -f2)

    iana_name=$(echo $orig|cut -d ',' -f3)
    openssl_name=$(openssl ciphers -V | grep -i "$hexval1,$hexval2"|awk '{print $3}')
    gnutls_name=$(gnutls-cli -l | grep -i "$hexval1, $hexval2"|awk '{print $1}')
    nss_name=$(grep "0x$(echo $hexval1|cut -d 'x' -f2)$(echo $hexval2|cut -d 'x' -f2)" NSS_TLS_Names.csv|cut -d ',' -f1)
done
