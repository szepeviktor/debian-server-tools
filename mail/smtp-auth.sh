#!/bin/bash
#
# Test SMTP authentication.
#
# VERSION       :0.2
# DATE          :2014-12-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl ca-certificates

INITIAL_WAIT="2"
CA_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"
MODE="auth"

Get_version() {
    local FILE="$1"
    local VER="$(grep -m1 "^# VERSION\s*:" "$FILE" | cut -d":" -f2-)"

    if [ -z "$VER" ]; then
        VER="(unknown)"
    fi
    echo "$VER"
}

Usage() {
    cat << USAGE
smtp-auth v$(Get_version "$0")
Usage: $(basename $0) [OPTION]
Test SMTP authentication.

  -a                test authentication support
  -p                PLAIN authentication
  -l                LOGIN authentication
  -c                CRAM-MD5 authentication
  -h <HOST>         the SMTP server
  -u <USER>         the SMTP username
  -P <PASS>         the SMTP password
USAGE
    exit
}

Require_all(){
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    if [ -z "$SMTP_HOST" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ]; then
        echo "Testing authentication needs a host, username and password." >&2
        usage
    fi
}

Smtp_auth() {
    local SMTP_HOST="$1"

    if [ -z "$SMTP_HOST" ]; then
        echo "Testing authentication support needs a hostname. Use \`-h\`." >&2
        exit 2
    fi

    (sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "QUIT") \
        | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${SMTP_HOST}:465" 2> /dev/null \
        | grep "^250-AUTH"
}

Smtp_plain() {
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    (sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo -ne "AUTH PLAIN \x00${SMTP_USER}\x00${SMTP_PASS}" | base64 --wrap=0; sleep 2
        echo "QUIT") \
        | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${SMTP_HOST}:465" 2> /dev/null
}

Smtp_login() {
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    (sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "AUTH LOGIN $(echo -n "$SMTP_USER" | base64 --wrap=0)"; sleep 2
        echo -n "$SMTP_PASS" | base64 --wrap=0; sleep 2
        echo "QUIT") \
        | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${SMTP_HOST}:465" 2> /dev/null
}

Python_cram_md5() {
    local SMTP_USER="$1"
    local SMTP_PASS="$2"
    local SMTP_CHALLANGE="$3"

    python << PYTHON
import sys, hmac, hashlib

def cram_md5_response(username, password, base64challenge):
    return (username + ' ' +
            hmac.new(password,
                     base64challenge.decode('base64'),
                     hashlib.md5).hexdigest()).encode('base64')

if __name__ == "__main__":
    print(cram_md5_response('$SMTP_USER', '$SMTP_PASS', '$SMTP_CHALLANGE'))
PYTHON
}


Smtp_md5() {
#FIXME expect?
exit 100
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    (sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "AUTH LOGIN CRAM-MD5"; sleep 2
        Python_cram_md5 "$SMTP_USER" "$SMTP_PASS" "${FIXME_PREVIOUS_ANWSER}"; sleep 2
        echo "QUIT") \
        | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${SMTP_HOST}:465" 2> /dev/null
}


which openssl &> /dev/null || exit 99

[ -z "$*" ] && Usage

while getopts ":aplch:u:P:" opt; do
    case $opt in
        a) # AUTH support
            MODE="auth"
            ;;
        p) # AUTH PLAIN
            MODE="plain"
            ;;
        l) # AUTH LOGIN
            MODE="login"
            ;;
        c) # AUTH CRAM-MD5
            MODE="md5"
            ;;
        h) # host
            SMTP_HOST="$OPTARG"
            ;;
        u) # user name
            SMTP_USER="$OPTARG"
            ;;
        P) # password
            SMTP_PASS="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            Usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            Usage
            ;;
    esac
done

case "$MODE" in
    auth)
        Smtp_auth "$SMTP_HOST"
        ;;
    plain)
        Smtp_plain "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"
        ;;
    login)
        Smtp_login "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"
        ;;
    md5)
        Smtp_md5 "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"
        ;;
esac
