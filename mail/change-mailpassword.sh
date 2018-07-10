#!/bin/bash
#
# Change password of a Courier account.
#
# VERSION       :0.1.2
# DATE          :2018-07-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-authdaemon apg
# DEPENDS       :/usr/local/share/password2remember/password2remember_hu.txt
# LOCATION      :/usr/local/sbin/change-mailpassword.sh

COURIER_AUTH_DBNAME="horde4"
COURIER_AUTH_DBTABLE="courier_horde"
WORDLIST_HU="/usr/local/share/password2remember/password2remember_hu.txt"

Error()
{
    echo "ERROR: $*"
    exit "$1"
}

set -e

if [[ $EUID -ne 0 ]]; then
    Error 100 "Only root is allowed to add mail accounts."
fi

USER_NAME="$1"
if [ -z "$USER_NAME" ]; then
    Error 1 "No account given."
fi

DEFAULT_PWD="$(apg -n 1 -M NC)"
# xkcd-style password
if [ -f "$WORDLIST_HU" ]; then
    DEFAULT_PWD="$(xkcdpass -d . -w "$WORDLIST_HU" -n 4)"
fi

# Ask for password
read -r -e -p "New password for ${USER_NAME}? " -i "$DEFAULT_PWD" PASS || Error 1 "Invalid password"

# MySQL authentication
if which mysql &> /dev/null \
    && grep -q '^authmodulelist=.*\bauthmysql\b' /etc/courier/authdaemonrc; then
    mysql "$COURIER_AUTH_DBNAME" <<EOF || Error 2 "Failed to update password"
-- USE ${COURIER_AUTH_DBNAME};
UPDATE \`${COURIER_AUTH_DBTABLE}\` SET \`crypt\`=ENCRYPT('${PASS}') WHERE \`id\`='${USER_NAME}';
EOF
fi

# Userdb authentication
if which userdb userdbpw &> /dev/null \
    && [ -r /etc/courier/userdb ] \
    && grep -q '^authmodulelist=.*\bauthuserdb\b' /etc/courier/authdaemonrc; then
    echo "$PASS" | userdbpw -md5 | userdb "$USER_NAME" set systempw || Error 3 "Failed to update password"
    makeuserdb || Error 4 "Failed to make userdb"
fi
