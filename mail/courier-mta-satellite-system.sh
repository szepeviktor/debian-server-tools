#!/bin/bash --version
#
# Courier MTA - deliver all messages to a smarthost
#
# Locally generated mail (sendmail, SMTP, notifications)
#     MTA <-- sendmail
#     MTA <-- MUA@localhost
#     MTA <-- DSN
#
# Delivering to 'smarthosts' or transactional email providers
#     MTA --> smarthost
#     MTA --> transactional providers

exit 0

#################### 'smarthost' configuration ####################

# Bounce handling
host -t MX $(hostname -f)
# Receive (bounce) mail for the satellite system (alias, acceptmailfor)

# Add the 'smarthost' to the SPF record of all sending domains
host -t TXT $SENDING_DOMAIN

# Allow receiving mail from the satellite system
editor /etc/courier/smtpaccess/default
#    %%IP%%<TAB>allow,RELAYCLIENT,AUTH_REQUIRED=0

# Deliver bounce messages
editor /etc/courier/aliases/system
#    @HOSTNAME: LOCAL-USER
editor /var/mail/DOMAIN/LOCAL-USER/.courier-default
#    LOCAL-USER

courier-restart.sh

################## END 'smarthost' configuration ##################



# Check for other MTA-s
if [ -n "$(aptitude search --disable-columns '?and(?installed, ?provides(mail-transport-agent))')" ]; then
    echo "There is another MTA installed." 2>&1
    exit 1
fi

apt-get install -y aptitude courier-mta courier-ssl
# Fix dependency on courier-authdaemon
if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' courier-mta)" lt "0.75.0-11"; then
    sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta
    update-rc.d courier-mta defaults
fi

# Restart script
( cd ${D}; ./install.sh mail/courier-restart.sh )

# Route mail to the smarthost
editor /etc/courier/esmtproutes
#     szepe.net: mail.szepe.net,25 /SECURITY=REQUIRED
#     : in-v3.mailjet.com,587 /SECURITY=REQUIRED
#     : SMART-HOST,587 /SECURITY=REQUIRED
# From jessie on
#     : SMART-HOST,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     SMART-HOST,587 USER-NAME PASSWORD

# SSL configuration
editor /etc/courier/courierd
# Use only TLSv1.2 and Modern profile WHEN 'smarthost' is ready (jessie) for it
# https://mozilla.github.io/server-side-tls/ssl-config-generator/
#     TLS_PROTOCOL="TLSv1.2"
#     TLS_CIPHER_LIST="" # Modern profile
#
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="" # Intermediate profile
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
#     TLS_CACHEFILE=/var/lib/courier/tmp/ssl_cache
#     TLS_CACHESIZE=524288

# Diffie-Hellman parameters
rm -f /etc/courier/dhparams.pem
DH_BITS=2048 nice /usr/sbin/mkdhparams
# DH params cron job
( cd ${D}; ./install.sh mail/courier-dhparams.sh )

# STARTTLS in client mode and 'smarthost' certificate verification
editor /etc/courier/courierd
#     ESMTP_USE_STARTTLS=1
#     ESMTP_TLS_VERIFY_DOMAIN=1
#     TLS_TRUSTCERTS=/etc/ssl/certs
#     TLS_VERIFYPEER=REQUIREPEER

# Listen on localhost and disable authentication
editor /etc/courier/esmtpd
#     ADDRESS=127.0.0.1
#     TCPDOPTS=" ... ... -noidentlookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS=""

# SMTP access for localhost
editor /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT

# No local domains
editor /etc/courier/locals
#     localhost
#     # Remove own hostname!

# Set hostname
editor /etc/courier/me
editor /etc/courier/defaultdomain
editor /etc/courier/dsnfrom

# Aliases
editor /etc/courier/aliases/system
#     nobody: postmaster
#     postmaster: postmaster@szepe.net

courier-restart.sh

# Test
echo "This is a t3st mail."|mailx -s "[first] The 1st outgoing mail" admin@szepe.net
