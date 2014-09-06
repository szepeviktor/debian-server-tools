#!/bin/bash
#
# Generate 8 easy to remember passwords.
# First option is the acrostic word, second is a number to append.
# Set P2R_LANG to any language name after you added the corresponding wordlist file.
# The fixed delimiter is period (the `-d` option of xkcdpass)
#
# VERSION       :0.2
# DATE          :2014-08-27
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :pip install xkcdpass
# WORDLIST_HU   :http://packetstormsecurity.com/files/32010/hungarian.gz.html
# WORDLIST_HU2  :http://sourceforge.net/projects/wordlist-hu/

P2R_LANG="hu"


ACROSTIC="$1"
NUMBER="$2"

# capitalize the first letter
capitalize() {
    local LOWERCASE="$1"

    echo -n "${LOWERCASE:0:1}" | tr '[:lower:]' '[:upper:]'
    echo -n "${LOWERCASE:1}"
}

[ -z "$ACROSTIC" ] || echo "a.c.r.o.s.t.i.c.: '${ACROSTIC}'"
[ -z "$NUMBER" ] || echo "number: '${NUMBER}'"

# generate 8 passwords
for N in $(seq 1 8); do
    XKCDPASS="$(xkcdpass -d . -w "password2remember_${P2R_LANG}.txt" -n 4 --max=7 -a "$ACROSTIC")"

    capitalize "$XKCDPASS"
    echo "$NUMBER"
done
