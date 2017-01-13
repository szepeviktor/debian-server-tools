#!/bin/bash
#
# Generate 8 easy to remember passwords.
#
# VERSION       :0.3.1
# DATE          :2017-01-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# WORDLIST_HU   :http://packetstormsecurity.com/files/32010/hungarian.gz.html
# WORDLIST_HU2  :http://sourceforge.net/projects/wordlist-hu/
# DEPENDS       :pip install xkcdpass
# LOCATION      :/usr/local/bin/password2remember.sh

# Installation
#     mkdir -p /usr/local/share/password2remember
#     cp -v ./password2remember_hu.txt /usr/local/share/password2remember/

# Set P2R_LANG to any language code after you added the corresponding wordlist file (password2remember_<CODE>.txt).
P2R_LANG="hu"
DELIMITER="."

# First option is the acrostic word, second is a number to append
ACROSTIC="$1"
NUMBER="$2"

# Capitalize the first letter
Capitalize() {
    local LOWERCASE="$1"

    echo -n "${LOWERCASE:0:1}" | tr '[:lower:]' '[:upper:]'
    echo -n "${LOWERCASE:1}"
}

# Add the number
Append_number() {
    echo "$NUMBER"
}

# Locate the word list file
Find_wordlist() {
    local WL="password2remember_${P2R_LANG}.txt"

    [ -r "/usr/local/share/password2remember/${WL}" ] \
        && WL="/usr/local/share/password2remember/${WL}"

    echo "$WL"
}

[ -z "$ACROSTIC" ] || echo "a.c.r.o.s.t.i.c.: '${ACROSTIC}'"
[ -z "$NUMBER" ] || echo "number: '${NUMBER}'"

# Generate 8 passwords choices
# shellcheck disable=SC2034
for N in {1..8}; do
    XKCDPASS="$(xkcdpass -d "$DELIMITER" -n 4 --max=7 -a "$ACROSTIC" -w "$(Find_wordlist)")"

    if [ -z "$NUMBER" ]; then
        echo "$XKCDPASS"
    else
        Capitalize "$XKCDPASS"
        Append_number
    fi
done
