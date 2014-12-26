#!/bin/bash
#
# Add a virtual mail account to courier-mta.
#
# VERSION       :0.2
# DATE          :2014-12-25
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/add-mailaccount.sh
# DEPENDS       :apt-get install courier-authdaemon courier-mta-ssl

ACCOUNT="$1"
MAILROOT="/var/mail"
VIRTUAL_UID="1999"
CA_CERTIFICATES="/etc/ssl/certs/ca-certificates.crt"

Error() {
    echo "ERROR: $*"
    exit $1
}

[ -z "$ACCOUNT" ] && Error 1 "No account given."
[ -d "$MAILROOT" ] || Error 1 "Mail root (${MAILROOT}) does not exist."

[ "$(id --user)" == 0 ] || Error 1 "Only root is allowed to add mail accounts."

# inputs
for V in EMAIL PASS DESC HOMEDIR; do
    case "$V" in
        EMAIL)
            DEFAULT="$ACCOUNT"
            ;;
        PASS)
            #TODO: xkcd-style password
            DEFAULT="$(pwgen 8 1)$((RANDOM % 10))"
            ;;
        HOMEDIR)
            DEFAULT="${MAILROOT}/${EMAIL##*@}/${EMAIL%%@*}"
            ;;
        *)
            DEFAULT=""
            ;;
    esac

    #read -e -p "${V}? " -i "$DEFAULT" VALUE
    #eval "$V"="'$VALUE'"
    read -e -p "${V}? " -i "$DEFAULT" "$V"
done

# check `virtual` user (1999:1999)
if ! getent passwd "$VIRTUAL_UID" &> /dev/null; then
    echo "Creating virtual user ..."
    addgroup --gid "$VIRTUAL_UID" virtual
    adduser --disabled-login --shell /usr/sbin/nologin --no-create-home --home /nonexistent \
        --gid "$VIRTUAL_UID" --uid "$VIRTUAL_UID" virtual
    getent passwd "$VIRTUAL_UID"
fi

# check domain
NEW_DOMAIN="${EMAIL##*@}"
grep -qr "^${NEW_DOMAIN//./\\.}$" /etc/courier/esmtpacceptmailfor.dir || Error 10 "This domain is not accepted here (${NEW_DOMAIN})"
grep -qr "^${NEW_DOMAIN//./\\.}$" /etc/courier/hosteddomains || echo "[WARNING] This domain is not hosted here (${NEW_DOMAIN})" >&2

# account folder and maildir
NEW_MAILDIR="${MAILROOT}/${NEW_DOMAIN}/${EMAIL%%@*}"
mkdir -v -p "${MAILROOT}/${NEW_DOMAIN}" || Error 12 "Failed to create dir: (${MAILROOT}/${NEW_DOMAIN})"
chown -v "$VIRTUAL_UID":"$VIRTUAL_UID" "${MAILROOT}/${NEW_DOMAIN}" || Error 13 "Cannot chown (${MAILROOT}/${NEW_DOMAIN})"
chmod -v o-rx "${MAILROOT}/${NEW_DOMAIN}" || Error 14 "Cannot chmod (${MAILROOT}/${NEW_DOMAIN})"
sudo -u virtual maildirmake "$NEW_MAILDIR" && echo "Maildir OK." || Error 15 "Cannot create maildir (${NEW_MAILDIR})"

# special folders
sudo -u virtual maildirmake -f Drafts "$NEW_MAILDIR" && echo "Drafts OK." || Error 20 "Cannot create Drafts folder"
sudo -u virtual maildirmake -f Sent "$NEW_MAILDIR" && echo "Sent OK." || Error 21 "Cannot create Sent folder"
sudo -u virtual maildirmake -f Trash "$NEW_MAILDIR" && echo "Trash OK." || Error 22 "Cannot create Trash folder"

# MySQL output
if which mysql \
    && grep -q "^authmodulelist=.*\bauthmysql\b" /etc/courier/authdaemonrc; then
    echo -e "\n---------------- >8 -----------------"
    mysql horde4 <<SQL
-- USE horde4;
INSERT INTO \`courier_horde\` (\`id\`, \`crypt\`, \`clear\`, \`name\`, \`uid\`, \`gid\`, \`home\`, \`maildir\`,
    \`defaultdelivery\`, \`quota\`, \`options\`, \`user_soft_expiration_date\`, \`user_hard_expiration_date\`, \`vac_msg\`, \`vac_subject\`, \`vac_stat\`) VALUES
('${EMAIL}', ENCRYPT('${PASS}'), '', '${DESC}', ${VIRTUAL_UID}, ${VIRTUAL_UID}, '${HOMEDIR}', '', '', '', '', NULL, NULL, '', '', 'N');
SQL
    echo -e "---------------- >8 -----------------\n"
fi

# userdb
if which userdb userdbpw &> /dev/null \
    && [ -r /etc/courier/userdb ] \
    && grep -q "^authmodulelist=.*\bauthuserdb\b" /etc/courier/authdaemonrc; then
    userdb "$EMAIL" set "home=${NEW_MAILDIR}" || Error 30 "Failed to add to userdb"
    userdb "$EMAIL" set "mail=${NEW_MAILDIR}" || Error 31 "Failed to add to userdb"
    userdb "$EMAIL" set "maildir=${NEW_MAILDIR}" || Error 32 "Failed to add to userdb"
    userdb "$EMAIL" set "uid=${VIRTUAL_UID}" || Error 33 "Failed to add to userdb"
    userdb "$EMAIL" set "gid=${VIRTUAL_UID}" || Error 34 "Failed to add to userdb"
    echo "$PASS" | userdbpw -md5 | userdb "$EMAIL" set systempw || Error 35 "Failed to add to userdb"
    [ -z "$DESC" ] || userdb "$EMAIL" set "fullname=${DESC}" || Error 36 "Failed to add to userdb"
    makeuserdb || Error 37 "Failed to make userdb"
fi

# SMTP authentication test
(sleep 2
    echo "EHLO $(hostname -f)"; sleep 2
    echo "AUTH PLAIN $(echo -ne "\x00${EMAIL}\x00${PASS}" | base64 --wrap=0)"; sleep 2
    echo "QUIT") \
    | openssl s_client -quiet -crlf -CAfile "$CA_CERTIFICATES" -connect "${EMAIL##*@}:465" 2> /dev/null
