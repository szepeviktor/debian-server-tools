#!/bin/bash
#
# Add a virtual mail account to Courier.
#
# VERSION       :0.6.3
# DATE          :2018-07-23
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install apg courier-authdaemon courier-mta-ssl
# DEPENDS       :/usr/local/bin/password2remember.sh
# LOCATION      :/usr/local/sbin/add-mailaccount.sh

VIRTUAL_UID="1999"
COURIER_AUTH_DBNAME="horde4"
#COURIER_AUTH_DBNAME="courier"
COURIER_AUTH_DBTABLE="courier_horde"
#COURIER_AUTH_DBTABLE="users"
# 1 GB
COURIER_ACCOUNT_QUOTA="$((1024**3))"
MAILROOT="/var/mail"
CA_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"

Error()
{
    echo "ERROR: $*" 1>&2
    exit "$1"
}

ACCOUNT="$1"

if [[ $EUID -ne 0 ]]; then
    Error 1 "Only root is allowed to add mail accounts."
fi
if [ -z "$ACCOUNT" ]; then
    Error 1 "No account given."
fi
if [ ! -d "$MAILROOT" ]; then
    Error 1 "Mail root (${MAILROOT}) does not exist."
fi

# Get inputs
for V in EMAIL PASS DESC HOMEDIR; do
    case "$V" in
        EMAIL)
            DEFAULT="$ACCOUNT"
            ;;
        PASS)
            DEFAULT="$(apg -n 1 -M NC)"
            # xkcd-style password
            WORDLIST_HU="/usr/local/share/password2remember/password2remember_hu.txt"
            if [ -f "$WORDLIST_HU" ] && hash xkcdpass 2> /dev/null; then
                DEFAULT="$(xkcdpass -d . -w "$WORDLIST_HU" -n 4)"
            fi
            ;;
        HOMEDIR)
            DEFAULT="${MAILROOT}/${EMAIL##*@}/${EMAIL%%@*}"
            ;;
        *)
            DEFAULT=""
            ;;
    esac

    read -r -e -p "${V}? " -i "$DEFAULT" "$V"
done

# Check "virtual" user (1999:1999)
if ! getent passwd "$VIRTUAL_UID" &> /dev/null; then
    echo "Creating virtual user ..."
    addgroup --gid "$VIRTUAL_UID" virtual
    adduser --gecos "" --disabled-login --shell /usr/sbin/nologin --no-create-home --home "$MAILROOT" \
        --gid "$VIRTUAL_UID" --uid "$VIRTUAL_UID" virtual
    getent passwd "$VIRTUAL_UID"
fi

# Validate email address format
# https://fightingforalostcause.net/content/misc/2006/compare-email-regex.php
grep -q -E '^[-a-z0-9_]+(\.[-a-z0-9_]+)*@[a-z0-9][-a-z0-9]*(\.[a-z0-9][-a-z0-9]+)*\.[a-z]+$' <<< "$EMAIL" \
    || Error 8 'Non-regular email address'

NEW_DOMAIN="${EMAIL##*@}"
NEW_MAILDIR="${HOMEDIR}/Maildir"

# Check home folder
test -d "$HOMEDIR" && Error 9 "This home ($HOMEDIR) already exists."

# Check domain
grep -q -F -x -r "${NEW_DOMAIN}" /etc/courier/esmtpacceptmailfor.dir \
    || echo "[WARNING] This domain is not accepted here (${NEW_DOMAIN})" 1>&2
grep -q -F -x -r "${NEW_DOMAIN}" /etc/courier/hosteddomains /etc/courier/locals \
    || echo "[WARNING] This domain is not hosted here (${NEW_DOMAIN})" 1>&2

# Account home folder and maildir
install -o "$VIRTUAL_UID" -g "$VIRTUAL_UID" -m "u=rwx" -d "${MAILROOT}/${NEW_DOMAIN}/${EMAIL%%@*}" \
    || Error 12 "Failed to create home: (${MAILROOT}/${NEW_DOMAIN})"
if sudo -u virtual -- maildirmake "$NEW_MAILDIR"; then
    echo "Maildir OK."
else
    Error 15 "Cannot create maildir (${NEW_MAILDIR})"
fi

# Quota
if sudo -u virtual -- maildirmake -q "${COURIER_ACCOUNT_QUOTA}S" "$NEW_MAILDIR"; then
    echo "Quota set."
else
    Error 16 "Cannot set quota"
fi

# Special folders
# See Horde/imp/config/backends.php 'special_mboxes'
if ! sudo -u virtual -- maildirmake -f "Drafts" "$NEW_MAILDIR"; then
    Error 20 "Cannot create Drafts folder"
fi
#HU: ln -s ".Drafts" "${NEW_MAILDIR}/.Piszkozat"
echo "Drafts OK."

if ! sudo -u virtual -- maildirmake -f "Junk" "$NEW_MAILDIR"; then
    Error 21 "Cannot create Junk folder"
fi
echo "WARNING - Quota counts symlinked folders" 1>&2
ln -s ".Junk" "${NEW_MAILDIR}/.Spam"
ln -s ".Junk" "${NEW_MAILDIR}/.Junk E-mail" # Outlook
ln -s ".Junk" "${NEW_MAILDIR}/.Unwanted" # Samsung Galaxy
#HU: ln -s ".Junk" "${NEW_MAILDIR}/.Lev&AOk-lszem&AOk-t"
echo "Junk OK."

if ! sudo -u virtual -- maildirmake -f "Sent" "$NEW_MAILDIR"; then
    Error 22 "Cannot create Sent folder"
fi
echo "Quota counts symlinked directories"
ln -s ".Sent" "${NEW_MAILDIR}/.Sent Items" # Outlook
ln -s ".Sent" "${NEW_MAILDIR}/.Sent Messages"
#HU: ln -s ".Sent" "${NEW_MAILDIR}/.Elk&APw-ld&APY-tt elemek"
echo "Sent OK."

if ! sudo -u virtual -- maildirmake -f "Trash" "$NEW_MAILDIR"; then
    Error 23 "Cannot create Trash folder"
fi
echo "Quota counts symlinked directories"
ln -s ".Trash" "${NEW_MAILDIR}/.Deleted Items" # Outlook
ln -s ".Trash" "${NEW_MAILDIR}/.Deleted Messages"
#HU: ln -s ".Trash" "${NEW_MAILDIR}/.T&APY-r&APY-lt elemek"
#HU: ln -s ".Trash" "${NEW_MAILDIR}/.Lomt&AOE-r"
echo "Trash OK."

# MySQL authentication
# shellcheck disable=SC1091,SC2154
if hash mysql 2> /dev/null \
    && ( source /etc/courier/authdaemonrc; echo "$authmodulelist"; ) | grep -F -w "authmysql"; then
    mysql "$COURIER_AUTH_DBNAME" <<EOF || Error 24 "Failed to insert into database"
-- USE ${COURIER_AUTH_DBNAME};
REPLACE INTO \`${COURIER_AUTH_DBTABLE}\` (\`id\`, \`crypt\`, \`clear\`, \`name\`,
    \`uid\`, \`gid\`, \`home\`, \`maildir\`, \`defaultdelivery\`, \`quota\`,
    \`options\`, \`user_soft_expiration_date\`, \`user_hard_expiration_date\`,
    \`vac_msg\`, \`vac_subject\`, \`vac_stat\`) VALUES
('${EMAIL}', ENCRYPT('${PASS}'), '', '${DESC}', ${VIRTUAL_UID}, ${VIRTUAL_UID},
'${HOMEDIR}', '${NEW_MAILDIR}', '', '', '', NULL, NULL, '', '', 'N');
EOF
    # Removal instruction
    echo "Remove user command:  -- USE ${COURIER_AUTH_DBNAME};"
    echo "                      DELETE FROM \`${COURIER_AUTH_DBTABLE}\` WHERE \`id\` = '${EMAIL}' LIMIT 1;"
fi

# UserDB authentication
# shellcheck disable=SC1091
if hash userdb userdbpw 2> /dev/null \
    && [ -r /etc/courier/userdb ] \
    && ( source /etc/courier/authdaemonrc; echo "$authmodulelist"; ) | grep -F -w "authuserdb"; then
    userdb "$EMAIL" set "home=${HOMEDIR}" || Error 30 "Failed to add to userdb"
    userdb "$EMAIL" set "mail=${NEW_MAILDIR}" || Error 31 "Failed to add to userdb"
    # `maildir` field is not necessary, see:  man makeuserdb
    #userdb "$EMAIL" set "maildir=${NEW_MAILDIR}" || Error 32 "Failed to add to userdb"
    userdb "$EMAIL" set "uid=${VIRTUAL_UID}" || Error 33 "Failed to add to userdb"
    userdb "$EMAIL" set "gid=${VIRTUAL_UID}" || Error 34 "Failed to add to userdb"
    # @TODO mkpasswd --method=sha-256 "$PASS" "$(openssl rand -base64 12)" |
    echo "$PASS" | userdbpw -md5 | userdb "$EMAIL" set systempw || Error 35 "Failed to add to userdb"
    test -z "$DESC" || userdb "$EMAIL" set "fullname=${DESC}" || Error 36 "Failed to add to userdb"
    makeuserdb || Error 37 "Failed to make userdb"

    # Removal instruction
    echo "Remove user command:  userdb \"$EMAIL\" del; makeuserdb"
    echo "Change password:  echo \"new.user.password\" | userdbpw -md5 | userdb \"$EMAIL\" set systempw; makeuserdb"
fi

# Removal instruction
echo "Remove home command:  rm -r -f '${HOMEDIR}'"

# Raise quote instruction (5 GB)
echo "Raise quote: sudo -u virtual -- maildirmake -q \$((5 * 1024**3))S '${NEW_MAILDIR}'"

# SMTP authentication test
{
    sleep 2
    echo "EHLO $(hostname -f)"
    sleep 2
    echo "AUTH PLAIN $(echo -ne "\\x00${EMAIL}\\x00${PASS}" | base64 --wrap=0)"
    sleep 2
    echo "QUIT"
} | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "$(hostname -f):465" 2> /dev/null \
    || Error 40 "Failed to authenticate"
