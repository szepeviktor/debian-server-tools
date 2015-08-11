#!/bin/bash
#
# Change password of a Courier account.
#
# VERSION       :0.1.0
# DATE          :2015-08-10
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install courier-authdaemon apg
# DEPENDS       :${D}/security/password2remember.sh
# LOCATION      :/usr/local/sbin/change-mailpassword.sh

COURIER_AUTH_DBNAME="horde4"
COURIER_AUTH_DBTABLE="courier_horde"
EMAIL="$1"

Error() {
    echo "ERROR: $*"
    exit $1
}

[ "$(id --user)" == 0 ] || Error 1 "Only root is allowed to add mail accounts."
[ -z "$EMAIL" ] && Error 1 "No account given."

DEFAULT="$(apg -n 1 -M NC)"
# xkcd-style password
WORDLIST_HU="/usr/local/share/password2remember/password2remember_hu.txt"
[ -f "$WORDLIST_HU" ] \
    && DEFAULT="$(xkcdpass -d . -w "$WORDLIST_HU" -n 4)"

# Ask for password
read -e -p "New password for ${ACCOUNT}? " -i "$DEFAULT" PASS || Error 1 "Invalid password"

# MySQL authentication
if which mysql &> /dev/null \
    && grep -q "^authmodulelist=.*\bauthmysql\b" /etc/courier/authdaemonrc; then
    mysql "$COURIER_AUTH_DBNAME" <<EOF || Error 2 "Failed to update password"
-- USE ${COURIER_AUTH_DBNAME};
UPDATE \`${COURIER_AUTH_DBTABLE}\` SET \`crypt\`=ENCRYPT('${PASS}') WHERE \`id\`='${EMAIL}';
EOF
fi

# userdb authentication
if which userdb userdbpw &> /dev/null \
    && [ -r /etc/courier/userdb ] \
    && grep -q "^authmodulelist=.*\bauthuserdb\b" /etc/courier/authdaemonrc; then
    echo "$PASS" | userdbpw -md5 | userdb "$EMAIL" set systempw || Error 3 "Failed to update password"
    makeuserdb || Error 4 "Failed to make userdb"
fi
