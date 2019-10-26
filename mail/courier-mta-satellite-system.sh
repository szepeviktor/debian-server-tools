#!/bin/bash
#
# Courier MTA - deliver all messages to a smarthost.
#

# Locally generated mail (sendmail, SMTP, notifications)
#     MTA <-- sendmail
#     MTA <-- MUA@localhost
#     MTA <-- DSN
#
# Delivering to 'smarthosts' or transactional email providers
#     MTA --> smarthost
#     MTA --> transactional provider
#     MTA --> transactional provider

#################### 'smarthost' configuration ####################

Smarthost_config()
{
    # Bounce handling
    host -t MX "$(hostname -f)"
    # Receive (bounce) mail for the satellite system (alias, acceptmailfor)

    # Add the 'smarthost' to the SPF record of all sending domains
    host -t TXT "$SENDING_DOMAIN"

    # Check SPF record of the 'smarthost'
    host -t TXT "$(hostname -f)"

    # Allow receiving mail from the satellite system
    editor /etc/courier/smtpaccess/default
    #    %%IP%%<TAB>allow,RELAYCLIENT,AUTH_REQUIRED=0

    # Deliver bounce messages
    editor /etc/courier/aliases/system
    #    @HOSTNAME: LOCAL-USER
    editor /var/mail/DOMAIN/LOCAL-USER/.courier-default
    #    LOCAL-USER

    courier-restart.sh
}

################## END 'smarthost' configuration ##################


Courier_config()
{
    local NEW="$1"
    local CURRENT="$2"
    local ORIGINAL
    local CWD="$(dirname "${BASH_SOURCE[0]}")"

    ORIGINAL="${CWD}/courier-config/${NEW}.orig"

    if [ -f "$ORIGINAL" ] && ! catconf "$CURRENT" | diff -q -w - "$ORIGINAL"; then
        echo "Courier MTA configuration has changed '${CURRENT}'" 1>&2
        exit 100
    fi

    # Keep permissions
    cat "${CWD}/courier-config/${NEW}" >"$CURRENT"
}

set -e -x

# shellcheck disable=SC1091
source debian-setup-functions.inc.sh

# Check for other MTA-s
if [ -n "$(aptitude search --disable-columns '?and(?installed, ?provides(mail-transport-agent))')" ]; then
    echo "There is another MTA installed." 2>&1
    exit 1
fi

# Courier MTA installation
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections -v
echo "courier-base courier-base/certnotice note" | debconf-set-selections -v
echo "courier-base courier-base/courier-user note" | debconf-set-selections -v
echo "courier-base courier-base/maildirpath note" | debconf-set-selections -v
echo "courier-base courier-base/maildir string Maildir" | debconf-set-selections -v
echo "courier-mta courier-mta/dsnfrom string mailer-daemon@$(hostname -f)" | debconf-set-selections -v
echo "courier-mta courier-mta/defaultdomain string" | debconf-set-selections -v
# Install-Recommends=false prevents installing: tk8.6 tcl8.6 xterm x11-utils
Pkg_install_quiet --no-install-recommends ca-certificates courier-mta

# @FIXME courier-mta package's incorrect default @markus
sed -e 's|^TLS_TRUSTCERTS=.*$|TLS_TRUSTCERTS=/etc/ssl/certs|' -i /etc/courier/courierd
sed -e 's|^TLS_TRUSTCERTS=.*$|TLS_TRUSTCERTS=/etc/ssl/certs|' -i /etc/courier/esmtpd
sed -e 's|^TLS_TRUSTCERTS=.*$|TLS_TRUSTCERTS=/etc/ssl/certs|' -i /etc/courier/esmtpd-ssl

# Install restart script
Dinstall mail/courier-restart.sh

# Route mail through the smarthost
Courier_config esmtproutes /etc/courier/esmtproutes

# @FIXME Set proper owner and group @markus
chown courier:root /etc/courier/esmtpauthclient

# Credentials for smarthosts
echo "#smtp.sparkpostmail.com,587 SMTP_Injection SPARKPOST-API-KEY" >>/etc/courier/esmtpauthclient

# Unused certificate file
install -o courier -g root -m 0600 /dev/null /etc/courier/esmtpd.pem

# Diffie-Hellman parameters
rm -f /etc/courier/dhparams.pem
# medium=2048, high=3072
DH_BITS=medium nice /usr/sbin/mkdhparams
# DH params cron job
Dinstall mail/courier-dhparams.sh

# SSL configuration, STARTTLS in client mode and smarthost certificate verification
Courier_config courierd /etc/courier/courierd
# Use only TLSv1.2 and Modern profile WHEN smarthost is ready for it (from jessie on)
# https://mozilla.github.io/server-side-tls/ssl-config-generator/
# Additional courierd config
Courier_config bofh /etc/courier/bofh

# Listen on localhost and disable authentication and disable identlookup,dnslookup
Courier_config esmtpd /etc/courier/esmtpd

# Don't listen on port SMTPS (465/tcp)
sed -e 's#^ESMTPDSSLSTART=.*$#ESMTPDSSLSTART=NO#' -i /etc/courier/esmtpd-ssl
service courier-mta-ssl stop

# Test GnuTLS prority strings
(
    TLS_PRIORITY="NORMAL:-CTYPE-OPENPGP"
    # shellcheck disable=SC1091
    source /etc/courier/courierd
    gnutls-cli --priority="$TLS_PRIORITY" --list >/dev/null
)
(
    TLS_PRIORITY="NORMAL:-CTYPE-OPENPGP"
    # shellcheck disable=SC1091
    source /etc/courier/esmtpd
    gnutls-cli --priority="$TLS_PRIORITY" --list >/dev/null
)
(
    TLS_PRIORITY="NORMAL:-CTYPE-OPENPGP"
    # shellcheck disable=SC1091
    source /etc/courier/esmtpd-ssl
    gnutls-cli --priority="$TLS_PRIORITY" --list >/dev/null
)

# SMTP access for localhost
Courier_config smtpaccess--default /etc/courier/smtpaccess/default

# Remove own hostname from locals
echo "localhost" >/etc/courier/locals

# Set hostname
hostname -f >/etc/courier/me
hostname -f >/etc/courier/defaultdomain
# /etc/courier/dsnfrom is set from debconf

# Allow long log reports
echo "$((25 * 1024**2))" >/etc/courier/sizelimit

# Aliases
sed -e 's#^postmaster:.*$#postmaster: postmaster@szepe.net\nnobody: postmaster#' -i /etc/courier/aliases/system

courier-restart.sh

# Test
echo "This is a t3st mail." | s-nail -s "[$(hostname -f)] The 1st outgoing mail" postmaster@szepe.net

echo "[NOTICE] Outbound SMTP (port 25) may be blocked."
