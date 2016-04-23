#!/bin/bash --version
#
# Courier MTA operate as a 'smarthost' and deliver mail to foreign hosts.
#

# Locally generated mail (sendmail, notifications)
#     MTA <-- sendmail (local monitoring scripts)
#     MTA <-- DSN
#
# Receiving as a 'smarthost' (inbound SMTP, SMTP-MSA)
#     MTA <-- Satellite systems (without authentication)
#     MTA <-- MUA (authenticated)
#
# Delivering to foreign hosts (outbound SMTP)
#     MTA --> Internet
#
# Forward to a foreign mailbox (SRS)
#     MTA --> another MTA

exit 0

# Add an MX record
host -t MX $(hostname -f)

echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections -v
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections -v
apt-get install -y aptitude courier-mta courier-mta-ssl

# Check for other MTA-s
aptitude search --disable-columns '?and(?installed, ?provides(mail-transport-agent))'

# Fix dependency on courier-authdaemon
if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' courier-mta)" le "0.75.0-11"; then
    sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta
    update-rc.d courier-mta defaults
    # courier-mta-ssl
    sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta-ssl
    update-rc.d courier-mta-ssl defaults
fi

# Restart script
cd ${D}; ./install.sh mail/courier-restart.sh

# SMTP access for localhost and satellite systems
editor /etc/courier/smtpaccess/default
#     127.0.0.1	allow,RELAYCLIENT
#     :0000:0000:0000:0000:0000:0000:0000:0001	allow,RELAYCLIENT
#
#     # Satellite systems
#     1.2.3.4	allow,RELAYCLIENT

# No local domains
editor /etc/courier/locals
#     localhost
#     # Remove hostnames!

# Set hostname
editor /etc/courier/me
editor /etc/courier/defaultdomain
editor /etc/courier/dsnfrom

# Aliases
editor /etc/courier/aliases/system
#     postmaster: |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS admin@szepe.net

# 1 day queue time
echo "1d" > /etc/courier/queuetime

# Listen on 587 and 465 and allow only authenticated clients even without PTR record
editor /etc/courier/esmtpd
#     ADDRESS=127.0.0.1
#     TCPDOPTS=" ... ... -noidentlookup -nodnslookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS="PLAIN LOGIN"
editor /etc/courier/esmtpd-msa
#     AUTH_REQUIRED=1
#     ADDRESS=0
#     ESMTPDSTART=YES
editor /etc/courier/esmtpd-ssl
#     AUTH_REQUIRED=1
#     SSLADDRESS=0

# SSL configuration
# https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=apache-2.4.14&openssl=1.0.1k&hsts=yes&profile=intermediate
editor /etc/courier/courierd
editor /etc/courier/esmtpd
editor /etc/courier/esmtpd-ssl
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
#     TLS_CACHEFILE=/var/lib/courier/tmp/ssl_cache
#     TLS_CACHESIZE=524288

# Diffie-Hellman parameters
rm -f /etc/courier/dhparams.pem
DH_BITS=2048 nice /usr/sbin/mkdhparams
# DH params cron job
cd ${D}; ./install.sh mail/courier-dhparams.sh

# Let's Encrypt certificate
cd
git clone https://github.com/letsencrypt/letsencrypt.git
./letsencrypt-auto certonly --standalone -d $(cat /etc/courier/me)
# -d DOMAIN2 -d DOMAIN3 --agree-tos --email EMAIL
cat /etc/letsencrypt/live/${DOMAIN}/privkey.pem /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
    > esmtpd.pem
cd ${D}; ./install.sh monitoring/cert-expiry.sh

# DKIM signature (zdkimfilter)
#     http://www.tana.it/sw/zdkimfilter/zdkimfilter.html
read -r -p "DKIM domain? " DOMAIN
apt-get install -y opendkim-tools zdkimfilter libidn2-0 libunistring0 libnettle4 libopendbx1
cd /etc/courier/filters/
install -o daemon -g root -m 700 -d privs
mkdir keys
# Configuration file
cp -v zdkimfilter.conf.dist zdkimfilter.conf
editor zdkimfilter.conf
#     header_canon_relaxed = Y
#     default_domain = $DOMAIN
#     add_auth_pass = Y
#     tempfail_on_error = Y
#     #add_ztags = Y
#     db_backend = sqlite3
#     db_host = /etc/courier/filters/
#     db_database = zdkim.sqlite
# http://www.linuxnetworks.de/doc/index.php/OpenDBX/Configuration#sqlite3_backend
install -b -o daemon -g root -m 600 /dev/null zdkim.sqlite
# New key
DKIM_SELECTOR="dkim$(date -u "+%Y%m")"
cd /etc/courier/filters/privs/
opendkim-genkey -v --domain="${DOMAIN}" --selector="$DKIM_SELECTOR"
chown -c daemon:root "$DKIM_SELECTOR"*
cd ../keys/
ln -vs "../privs/dkim${DKIM_SELECTOR}.private" "${DOMAIN}"
cd ../
# Add new key to DNS
cat "/etc/courier/filters/privs/dkim${DKIM_SELECTOR}.txt"
host -t TXT "${DKIM_SELECTOR}._domainkey.${DOMAIN}"
# Start filter
filterctl start zdkimfilter; ls -l /etc/courier/filters/active

# SRS (Sender Rewriting Scheme)
apt-get install -y apg couriersrs
couriersrs -v
apg -a 1 -M LCNS -m 30 -n 1 > /etc/srs_secret
chown -c root:daemon /etc/srs_secret; chmod -c 640 /etc/srs_secret
# Create system aliases SRS0 and SRS1
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS0-default
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS1-default
# SRS domain cannot be a virtual domain
#     # @virt.dom: an@account.net
# Add forwarding alias
#     user:  |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS username@external-domain.tld

courier-restart.sh

# Test
echo "This is a t3st mail."|mailx -s "[first] The 1st outgoing mail" admin@szepe.net

#tail -f /var/log/syslog
journalctl -f

# Accounts
mkdir /etc/courier/esmtpacceptmailfor.dir; makeacceptmailfor
install -b -o root -g root -m 644 /dev/null /etc/courier/hosteddomains; makehosteddomains
editor /etc/courier/authdaemonrc
#     authmodulelist="authuserdb"
install -b -o root -g root -m 600 /dev/null /etc/courier/userdb; makeuserdb

./add-mailaccount.sh USER@DOMAIN
