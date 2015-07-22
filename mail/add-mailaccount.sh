#!/bin/bash
#
# Add a virtual mail account to courier-mta.
#
# VERSION       :0.4.0
# DATE          :2015-07-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/add-mailaccount.sh
# DEPENDS       :apt-get install courier-authdaemon courier-mta-ssl pwgen
# DEPENDS       :${D}/security/password2remember.sh

VIRTUAL_UID="1999"
COURIER_AUTH_DBNAME="horde4"
COURIER_AUTH_DBTABLE="courier_horde"

Error() {
    echo "ERROR: $*"
    exit $1
}

ACCOUNT="$1"
MAILROOT="/var/mail"
CA_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"

[ "$(id --user)" == 0 ] || Error 1 "Only root is allowed to add mail accounts."
[ -z "$ACCOUNT" ] && Error 1 "No account given."
[ -d "$MAILROOT" ] || Error 1 "Mail root (${MAILROOT}) does not exist."

# inputs
for V in EMAIL PASS DESC HOMEDIR; do
    case "$V" in
        EMAIL)
            DEFAULT="$ACCOUNT"
            ;;
        PASS)
            # @TODO Use apg
            DEFAULT="$(pwgen 8 1)$((RANDOM % 10))"
            # xkcd-style password
            WORDLIST_HU="/usr/local/share/password2remember/password2remember_hu.txt"
            [ -f "$WORDLIST_HU" ] \
                && DEFAULT="$(xkcdpass -d . -w "$WORDLIST_HU" -n 4)"
            ;;
        HOMEDIR)
            DEFAULT="${MAILROOT}/${EMAIL##*@}/${EMAIL%%@*}"
            ;;
        *)
            DEFAULT=""
            ;;
    esac

    read -e -p "${V}? " -i "$DEFAULT" "$V"
done

# check `virtual` user (1999:1999)
if ! getent passwd "$VIRTUAL_UID" &> /dev/null; then
    echo "Creating virtual user ..."
    addgroup --gid "$VIRTUAL_UID" virtual
    adduser --gecos "" --disabled-login --shell /usr/sbin/nologin --no-create-home --home /nonexistent \
        --gid "$VIRTUAL_UID" --uid "$VIRTUAL_UID" virtual
    getent passwd "$VIRTUAL_UID"
fi

# check email format
# https://fightingforalostcause.net/content/misc/2006/compare-email-regex.php
grep -qE '^[-a-z0-9_]+(\.[-a-z0-9_]+)*@[a-z0-9_]([-a-z0-9_])*(\.[-a-z0-9_]+)+$' <<< "$EMAIL" || Error 8 'Non-regular email address'

NEW_DOMAIN="${EMAIL##*@}"
NEW_MAILDIR="${MAILROOT}/${NEW_DOMAIN}/${EMAIL%%@*}/Maildir"
#?

# check home
[ -d "$HOMEDIR" ] && Error 9 "This home ($HOMEDIR) already exists."

# check domain
grep -qFxr "${NEW_DOMAIN}" /etc/courier/locals /etc/courier/esmtpacceptmailfor.dir || Error 10 "This domain is not accepted here (${NEW_DOMAIN})"
grep -qFxr "${NEW_DOMAIN}" /etc/courier/hosteddomains || echo "[WARNING] This domain is not hosted here (${NEW_DOMAIN})" >&2

# account folder and maildir
install -o "$VIRTUAL_UID" -g "$VIRTUAL_UID" -m "u=rwx" -d "${MAILROOT}/${NEW_DOMAIN}/${EMAIL%%@*}" || Error 12 "Failed to install dir: (${MAILROOT}/${NEW_DOMAIN})"
#?
sudo -u virtual -- maildirmake "$NEW_MAILDIR" && echo "Maildir OK." || Error 15 "Cannot create maildir (${NEW_MAILDIR})"

# special folders
sudo -u virtual -- maildirmake -f Drafts "$NEW_MAILDIR" && echo "Drafts OK." || Error 20 "Cannot create Drafts folder"
sudo -u virtual -- maildirmake -f Sent "$NEW_MAILDIR" && echo "Sent OK." || Error 21 "Cannot create Sent folder"
sudo -u virtual -- maildirmake -f Trash "$NEW_MAILDIR" && echo "Trash OK." || Error 22 "Cannot create Trash folder"
# removal instruction
echo "Remove home command:  rm -rf '${HOMEDIR}'"

# MySQL authentication
if which mysql &> /dev/null \
    && grep -q "^authmodulelist=.*\bauthmysql\b" /etc/courier/authdaemonrc; then
    mysql "$COURIER_AUTH_DBNAME" <<SQL && echo "User inserted into database. OK."
-- USE ${COURIER_AUTH_DBNAME};
REPLACE INTO \`${COURIER_AUTH_DBTABLE}\` (\`id\`, \`crypt\`, \`clear\`, \`name\`, \`uid\`, \`gid\`, \`home\`, \`maildir\`,
    \`defaultdelivery\`, \`quota\`, \`options\`, \`user_soft_expiration_date\`, \`user_hard_expiration_date\`, \`vac_msg\`, \`vac_subject\`, \`vac_stat\`) VALUES
('${EMAIL}', ENCRYPT('${PASS}'), '', '${DESC}', ${VIRTUAL_UID}, ${VIRTUAL_UID}, '${HOMEDIR}', '${NEW_MAILDIR}', '', '', '', NULL, NULL, '', '', 'N');
SQL
    # removal instruction
    echo "Remove user command:  -- USE ${COURIER_AUTH_DBNAME};"
    echo "                      DELETE FROM \`${COURIER_AUTH_DBTABLE}\` WHERE \`id\` = '${EMAIL}' LIMIT 1;"
fi

# userdb authentication
if which userdb userdbpw &> /dev/null \
    && [ -r /etc/courier/userdb ] \
    && grep -q "^authmodulelist=.*\bauthuserdb\b" /etc/courier/authdaemonrc; then
    userdb "$EMAIL" set "home=${HOMEDIR}" || Error 30 "Failed to add to userdb"
    userdb "$EMAIL" set "mail=${NEW_MAILDIR}" || Error 31 "Failed to add to userdb"
    # 'maildir' is not necessary, see:  man makeuserdb
    #userdb "$EMAIL" set "maildir=${NEW_MAILDIR}" || Error 32 "Failed to add to userdb"
    userdb "$EMAIL" set "uid=${VIRTUAL_UID}" || Error 33 "Failed to add to userdb"
    userdb "$EMAIL" set "gid=${VIRTUAL_UID}" || Error 34 "Failed to add to userdb"
    echo "$PASS" | userdbpw -md5 | userdb "$EMAIL" set systempw || Error 35 "Failed to add to userdb"
    [ -z "$DESC" ] || userdb "$EMAIL" set "fullname=${DESC}" || Error 36 "Failed to add to userdb"
    makeuserdb || Error 37 "Failed to make userdb"
    # removal instruction
    echo "Remove user command:  userdb '$EMAIL' del"
fi

# SMTP authentication test
(sleep 2
    echo "EHLO $(hostname -f)"; sleep 2
    echo "AUTH PLAIN $(echo -ne "\x00${EMAIL}\x00${PASS}" | base64 --wrap=0)"; sleep 2
    echo "QUIT") \
    | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${EMAIL##*@}:465" 2> /dev/null
