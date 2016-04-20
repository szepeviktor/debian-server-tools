#!/bin/bash --version

exit 0

# Courier MTA - deliver all messages to a smarthost
#
#     1. Send-only servers don't receive emails.
#     1. Send-only servers don't have local domain names.
#     1. They should have an MX record pointing to the smarthost.
#     1. Smarthost should receive all emails addressed to send-only server's domain name.
clear; apt-get install -y courier-mta courier-mta-ssl
# Fix dependency on courier-authdaemon
sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta
update-rc.d courier-mta defaults
# Check for other MTA-s
dpkg -l | grep -E "postfix|exim"
cd ${D}; ./install.sh mail/courier-restart.sh
# Smarthost
editor /etc/courier/esmtproutes
#     szepe.net: mail.szepe.net,25 /SECURITY=REQUIRED
#     : %SMART-HOST%,587 /SECURITY=REQUIRED
#     : in-v3.mailjet.com,587 /SECURITY=REQUIRED
# From jessie on - requires ESMTP_TLS_VERIFY_DOMAIN=1 and TLS_VERIFYPEER=PEER
#     : %SMART-HOST%,465 /SECURITY=SMTPS
editor /etc/courier/esmtpauthclient
#     smtp.mandrillapp.com,587 MANDRILL@ACCOUNT API-KEY
# Diffie-Hellman parameter
DH_BITS=2048 nice /usr/sbin/mkdhparams
# DH params cron.monthly job
# @TODO Move it to a file
echo -e '#!/bin/bash\nDH_BITS=2048 nice /usr/sbin/mkdhparams 2> /dev/null\nexit 0' > /usr/local/sbin/courier-dhparams.sh
echo -e '#!/bin/bash\n/usr/local/sbin/courier-dhparams.sh' > /etc/cron.monthly/courier-dhparams
chmod 755 /usr/local/sbin/courier-dhparams.sh /etc/cron.monthly/courier-dhparams
# SSL setup
editor /etc/courier/courierd
editor /etc/courier/esmtpd
editor /etc/courier/esmtpd-ssl
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="" See https://mozilla.github.io/server-side-tls/ssl-config-generator/
#     TLS_DHPARAMS=/etc/courier/courier-dhparams.pem
#     TLS_CACHEFILE=/var/lib/courier/tmp/ssl_cache
#     TLS_CACHESIZE=524288
editor /etc/courier/esmtpd
#     ADDRESS=127.0.0.1
#     TCPDOPTS=" ... ... -noidentlookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS=""
editor /etc/courier/esmtpd-ssl
#     SSLADDRESS=127.0.0.1
editor /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT
editor /etc/courier/me
# Check MX record
host -t MX $(cat /etc/courier/me)
editor /etc/courier/defaultdomain
# SPF - Add this server to the SPF record of its domains
editor /etc/courier/dsnfrom
editor /etc/courier/locals
#     localhost
#     # Remove own hostname!
editor /etc/courier/aliases/system
#     postmaster: |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS admin@szepe.net
courier-restart.sh
# Allow unauthenticated SMTP traffic from this server on the smarthost
#     editor /etc/courier/smtpaccess/default
#         %%IP%%<TAB>allow,RELAYCLIENT,AUTH_REQUIRED=0

# Receive bounce messages on the smarthost
#     editor /etc/courier/aliases/system
#         @HOSTNAME.TLD: LOCAL-USER
#     editor /var/mail/DOMAIN/USER/.courier-default
#         LOCAL-USER
#     courier-restart.sh
echo "This is a t3st mail."|mailx -s "[first] Subject of the 1st email" viktor@szepe.net
