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

} # SmarthostConfig

################## END 'smarthost' configuration ##################



# Check for other MTA-s
if [ -n "$(aptitude search --disable-columns '?and(?installed, ?provides(mail-transport-agent))')" ]; then
    echo "There is another MTA installed." 2>&1
    exit 1
fi

# Courier MTA installation #
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections -v
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections -v
# Install-Recommends=false prevents installing: tk8.6 tcl8.6 xterm x11-utils
apt-get install -o APT::Install-Recommends=false -y ca-certificates courier-mta courier-ssl
# Fix dependency on courier-authdaemon
if dpkg --compare-versions "$(dpkg-query --show --showformat="\${Version}" courier-mta)" lt "0.75.0-11"; then
    sed -i -e '1,20s|^#\s\+Required-Start:\s.*$|& courier-authdaemon|' /etc/init.d/courier-mta
    #update-rc.d courier-mta defaults
fi

# Install restart script #
Dinstall mail/courier-restart.sh

# Route mail through the smarthost #
editor /etc/courier/esmtproutes
#     szepe.net: mail.szepe.net,25 /SECURITY=REQUIRED
#     : smtp.mailgun.org,587 /SECURITY=REQUIRED
#     : email-smtp.eu-west-1.amazonaws.com,587 /SECURITY=REQUIRED
#     : SMART-HOST,587 /SECURITY=REQUIRED
# From jessie on
#     : SMART-HOST,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     SMART-HOST,587 USER-NAME PASSWORD

# Unused certificate file
install -o daemon -g root -m 0600 /dev/null /etc/courier/esmtpd.pem
# SSL configuration #
editor /etc/courier/courierd
# Use only TLSv1.2 and Modern profile WHEN 'smarthost' is ready (jessie) for it
# https://mozilla.github.io/server-side-tls/ssl-config-generator/
#     # Modern profile as of 2016-08-28
#     TLS_PROTOCOL="TLSv1.2"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256"
#
#     # Intermediate profile as of 2016-08-28
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
#
#     TLS_COMPRESSION=NULL
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
#     TLS_CACHEFILE=/var/lib/courier/couriersslcache
#     TLS_CACHESIZE=524288

# Diffie-Hellman parameters
rm -f /etc/courier/dhparams.pem
DH_BITS=2048 nice /usr/sbin/mkdhparams
# DH params cron job
Dinstall mail/courier-dhparams.sh

# STARTTLS in client mode and smarthost certificate verification #
editor /etc/courier/courierd
#     ESMTP_USE_STARTTLS=1
#     ESMTP_TLS_VERIFY_DOMAIN=1
#     TLS_TRUSTCERTS=/etc/ssl/certs
#     TLS_VERIFYPEER=REQUIREPEER
#     # Courier verifies against resolved CNAME-s!
#     # https://github.com/svarshavchik/courier-libs/commit/5e522ab14f45c6f4f43c43e32a2f72fbf6354f1c
#     # addcr|ESMTP_USE_STARTTLS=1 ESMTP_TLS_VERIFY_DOMAIN=1 TLS_PROTOCOL=TLS1 TLS_VERIFYPEER=REQUIREPEER TLS_TRUSTCERTS=/etc/ssl/certs /usr/bin/couriertls -port=587 -protocol=smtp -host=smart.host.tld

# Listen on localhost and disable authentication
editor /etc/courier/esmtpd
#     ADDRESS=127.0.0.1
#     # Don't look up localhost
#     TCPDOPTS="-stderrlogger=/usr/sbin/courierlogger -noidentlookup -nodnslookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS=""

# SMTP access for localhost
editor /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT

# Remove own hostname from locals
echo "localhost" > /etc/courier/locals

# Set hostname #
editor /etc/courier/me
editor /etc/courier/defaultdomain
editor /etc/courier/dsnfrom

# Aliases #
editor /etc/courier/aliases/system
#     f2bleanmail: |/usr/local/sbin/leanmail.sh admin@szepe.net
#     nobody: postmaster
#     postmaster: postmaster@szepe.net

courier-restart.sh

# Test
echo "This is a t3st mail." | mailx -s "[$(hostname -f)] The 1st outgoing mail" admin@szepe.net

echo "Outbound SMTP (port 25) may be blocked."
