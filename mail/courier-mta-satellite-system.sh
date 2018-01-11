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
#     MTA --> transactional providers

set -e -x

. debian-setup-functions

#################### 'smarthost' configuration ####################

SmarthostConfig() {

# Bounce handling
host -t MX "$(hostname -f)"
# Receive (bounce) mail for the satellite system (alias, acceptmailfor)

# Add the 'smarthost' to the SPF record of all sending domains
host -t TXT "$SENDING_DOMAIN"

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

Courier_config() {
    local NEW="$1"
    local CURRENT="$2"
    local ORIGINAL

    ORIGINAL="mail/courier-config/${NEW}.orig"

    if [ -f "$ORIGINAL" ] && ! catconf "$CURRENT" | diff -q -w - "$ORIGINAL"; then
        echo "Courier MTA configuration has changed '${CURRENT}'" 1>&2
        exit 100
    fi

    cp -v -f "mail/courier-config/${NEW}" "$CURRENT"
}

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
apt-get install -o APT::Install-Recommends=false -y ca-certificates courier-mta

# Install restart script
Dinstall mail/courier-restart.sh

# Route mail through the smarthost
Courier_config esmtproutes /etc/courier/esmtproutes
#     szepe.net: mail.szepe.net,25 /SECURITY=REQUIRED
#     : email-smtp.eu-west-1.amazonaws.com,587 /SECURITY=REQUIRED
#     : smtp.sparkpostmail.com,587 /SECURITY=REQUIRED
#     : smtp-relay.gmail.com,587 /SECURITY=REQUIRED
# Credentials for smarthosts
echo "#SMART-HOST,587 USER-NAME PASSWORD" > /etc/courier/esmtpauthclient
#     #SMART-HOST,587 USER-NAME PASSWORD

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
# Use only TLSv1.2 and Modern profile WHEN 'smarthost' is ready for it (from jessie on)
# https://mozilla.github.io/server-side-tls/ssl-config-generator/
#     # Modern profile as of 2016-08-28
#     TLS_PROTOCOL="TLSv1.2"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256"
#
#     # Intermediate profile as of 2016-08-28
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
#     ESMTP_USE_STARTTLS=1
#     ESMTP_TLS_VERIFY_DOMAIN=1
#     TLS_TRUSTCERTS=/etc/ssl/certs
#     TLS_VERIFYPEER=REQUIREPEER

# Listen on localhost and disable authentication
Courier_config esmtpd /etc/courier/esmtpd
#     ADDRESS=127.0.0.1
#     # Don't look up localhost
#     TCPDOPTS="-stderrlogger=/usr/sbin/courierlogger -noidentlookup -nodnslookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS=""

# @TODO Fix courier-mta package's default value
sed -i -e 's|^TLS_TRUSTCERTS=.*$|TLS_TRUSTCERTS=/etc/ssl/certs|' /etc/courier/esmtpd-ssl
# Don't listen on port SMTPS (465/tcp)
sed -i -e 's|^ESMTPDSSLSTART=.*$|ESMTPDSSLSTART=NO|' /etc/courier/esmtpd-ssl
#     ESMTPDSSLSTART=NO

# SMTP access for localhost
Courier_config smtpaccess--default /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT

# Remove own hostname from locals
echo "localhost" > /etc/courier/locals

# Set hostname
hostname -f > /etc/courier/me
hostname -f > /etc/courier/defaultdomain
# /etc/courier/dsnfrom set from debconf

# Aliases
sed -i -e 's|^postmaster:.*$|postmaster: postmaster@szepe.net\nnobody: postmaster|' /etc/courier/aliases/system
#     f2bleanmail: |/usr/local/sbin/leanmail.sh admin@szepe.net
#     postmaster: postmaster@szepe.net
#     nobody: postmaster

courier-restart.sh

# Test
echo "This is a t3st mail." | mail -s "[$(hostname -f)] The 1st outgoing mail" admin@szepe.net

echo "Outbound SMTP (port 25) may be blocked."
