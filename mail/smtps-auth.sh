#!/bin/bash
#
# Test SMTPS authentication.
#
# VERSION       :0.5.1
# DATE          :2016-05-29
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install openssl ca-certificates
# LOCATION      :/usr/local/bin/smtps-auth.sh

# Use Swaks instead: http://www.jetmore.org/john/code/swaks/

INITIAL_WAIT="2"
CA_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"
MODE="auth"
SMTP_PORT="465"
STARTTLS=""

Get_version()
{
    local FILE="$1"
    local VER

    VER="$(grep -m 1 '^# VERSION\s*:' "$FILE" | cut -d ":" -f 2-)"

    if [ -z "$VER" ]; then
        VER="(unknown)"
    fi

    echo "$VER"
}

Usage()
{
    cat <<EOF
smtp-auth v$(Get_version "$0")
Usage: $(basename "$0") <OPTION> ...
Test SMTPS authentication.

  -s <SERVER>       SMTPS server
  -p <PORT>         SMTPS port (default: 465)
  -u <USER>         SMTPS username
  -w <PASSWORD>     SMTPS password
  -a                Test authentication support
  -P                PLAIN authentication
  -L                LOGIN authentication
  -C                CRAM-MD5 authentication
EOF
    exit 0
}

Require_all()
{
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    if [ -z "$SMTP_HOST" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ]; then
        echo "Testing authentication needs a host, username and password." 1>&2
        Usage
    fi
}

Smtp_auth()
{
    local SMTP_HOST="$1"

    if [ -z "$SMTP_HOST" ]; then
        echo "Testing authentication support needs a hostname. Use -s SERVER" 1>&2
        exit 2
    fi

    {
        sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "QUIT"
    } | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" \
        -connect "${SMTP_HOST}:${SMTP_PORT}" ${STARTTLS} 2>/dev/null | grep '^250-AUTH'
}

Smtp_plain()
{
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    {
        sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        # It is also possible to send the username and password, together with the AUTH PLAIN command, as a single line.
        echo "AUTH PLAIN $(echo -ne "\\x00${SMTP_USER}\\x00${SMTP_PASS}" | base64 --wrap=0)"; sleep 2
        echo "QUIT"
    } | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" \
        -connect "${SMTP_HOST}:${SMTP_PORT}" ${STARTTLS} 2>/dev/null | grep '^235 '
}

Smtp_login()
{
    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    {
        sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "AUTH LOGIN"; sleep 2
        echo -n "$SMTP_USER" | base64 --wrap=0; echo; sleep 2
        echo -n "$SMTP_PASS" | base64 --wrap=0; echo; sleep 2
        echo "QUIT"
    } | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" \
        -connect "${SMTP_HOST}:${SMTP_PORT}" ${STARTTLS} 2>/dev/null | grep '^235 '
}

Python_cram_md5()
{
    local SMTP_USER="$1"
    local SMTP_PASS="$2"
    local SMTP_CHALLANGE="$3"

    python <<EOF
import sys, hmac, hashlib

def cram_md5_response(username, password, base64challenge):
    return (username + ' ' +
            hmac.new(password,
                     base64challenge.decode('base64'),
                     hashlib.md5).hexdigest()).encode('base64')

if __name__ == "__main__":
    print(cram_md5_response('$SMTP_USER', '$SMTP_PASS', '$SMTP_CHALLANGE'))
EOF
}


Smtp_md5()
{
# @FIXME expect?
exit 100

    local SMTP_HOST="$1"
    local SMTP_USER="$2"
    local SMTP_PASS="$3"

    Require_all "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASS"

    {
        sleep "$INITIAL_WAIT"
        echo "EHLO $(hostname -f)"; sleep 2
        echo "AUTH LOGIN CRAM-MD5"; sleep 2
        Python_cram_md5 "$SMTP_USER" "$SMTP_PASS" "${FIXME_PREVIOUS_ANWSER}"; sleep 2
        echo "QUIT"
    } | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" \
        -connect "${SMTP_HOST}:${SMTP_PORT}" ${STARTTLS} 2>/dev/null
}

which openssl &>/dev/null || exit 99

test -z "$*" && Usage

while getopts ":aPLCs:p:u:w:h" OPTION; do
    case "$OPTION" in
        a) # Test AUTH support
            MODE="auth"
            ;;
        P) # AUTH PLAIN
            MODE="plain"
            ;;
        L) # AUTH LOGIN
            MODE="login"
            ;;
        C) # AUTH CRAM-MD5
            MODE="md5"
            ;;
        s) # Server
            SMTP_HOST="$OPTARG"
            ;;
        p) # Port
            SMTP_PORT="$OPTARG"
            test "$SMTP_PORT" == 465 || STARTTLS="-starttls smtp"
            ;;
        u) # User name
            SMTP_USER="$OPTARG"
            ;;
        w) # Password
            SMTP_PASS="$OPTARG"
            ;;
        h)
            Usage
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" 1>&2
            Usage
            ;;
        :)
            echo "Option -${OPTARG} requires an argument." 1>&2
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
