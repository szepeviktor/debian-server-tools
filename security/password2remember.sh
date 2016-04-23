#!/bin/bash
#
# Generate 8 easy to remember passwords.
# First option is the acrostic word, second is a number to append.
#
# Set P2R_LANG to any language code after you added the corresponding wordlist file (password2remember_<CODE>.txt).
#
# VERSION       :0.3.0
# DATE          :2015-01-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# WORDLIST_HU   :http://packetstormsecurity.com/files/32010/hungarian.gz.html
# WORDLIST_HU2  :http://sourceforge.net/projects/wordlist-hu/
# DEPENDS       :pip install xkcdpass
# LOCATION      :/usr/local/bin/password2remember.sh

# Install
#     mkdir -p /usr/local/share/password2remember
#     cp -v ./password2remember_hu.txt /usr/local/share/password2remember/

P2R_LANG="hu"
DELIMITER="."

ACROSTIC="$1"
NUMBER="$2"

# capitalize the first letter
Capitalize() {
    local LOWERCASE="$1"

    echo -n "${LOWERCASE:0:1}" | tr '[:lower:]' '[:upper:]'
    echo -n "${LOWERCASE:1}"
}

# add the number
Append_number() {
    echo "$NUMBER"
}

# locate the word list file
Find_wordlist() {
    local WL="password2remember_${P2R_LANG}.txt"

    [ -r "/usr/local/share/password2remember/${WL}" ] \
        && WL="/usr/local/share/password2remember/${WL}"

    echo "$WL"
}


[ -z "$ACROSTIC" ] || echo "a.c.r.o.s.t.i.c.: '${ACROSTIC}'"
[ -z "$NUMBER" ] || echo "number: '${NUMBER}'"

# generate 8 passwords choices
for N in $(seq 1 8); do
    XKCDPASS="$(xkcdpass -d "$DELIMITER" -w "$(Find_wordlist)" -n 4 --max=7 -a "$ACROSTIC")"

    if [ -z "$NUMBER" ]; then
        echo "$XKCDPASS"
    else
        Capitalize "$XKCDPASS"
        Append_number
    fi
done
