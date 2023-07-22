#!/bin/bash --version
#
# Courier MTA - operate as a smarthost, deliver outbound messages.
#

# Locally generated mail (sendmail, notifications)
#     MTA <-- sendmail (local monitoring scripts)
#     MTA <-- DSN
#
# Receiving as a smarthost (inbound SMTP-MSA, SMTPS)
#     MTA <-- Satellite systems (without authentication)
#     MTA <-- MUA (authenticated)
#
# Delivering to foreign hosts (outbound SMTP)
#     MTA --> Internet
#
# Forward to a foreign mailbox (SRS)
#     MTA --> another MTA
# @TODO Prefer pulling mail from local mailbox over forwarding

exit 0

# Add an MX record
host -t MX $(hostname -f)
# Receive mail on a mailserver with accounts (alias, acceptmailfor)

echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections -v
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections -v
# Install-Recommends=false prevents installing: tk8.6 tcl8.6 xterm x11-utils
apt-get install --no-install-recommends -y aptitude apg courier-mta courier-ssl courier-mta-ssl

# Check for other MTA-s
aptitude search --disable-columns '?and(?installed, ?provides(mail-transport-agent))'

# Fix dependency on courier-authdaemon
if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' courier-mta)" lt "0.75.0-11"; then
    sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta
    update-rc.d courier-mta defaults
    # courier-mta-ssl
    sed -i '1,20s/^\(#\s\+Required-Start:\s.*\)$/\1 courier-authdaemon/' /etc/init.d/courier-mta-ssl
    update-rc.d courier-mta-ssl defaults
fi

# Have systemd restart courier
mkdir /etc/systemd/system/courier-authdaemon.service.d
cat <<"EOF" > /etc/systemd/system/courier-authdaemon.service.d/restart-always.conf
[Unit]
# Missing from sysvinit file
Description=Courier authentication services

[Service]
PIDFile=/run/courier/authdaemon/pid
RemainAfterExit=no
Restart=always
EOF

mkdir /etc/systemd/system/courier-mta.service.d
cat <<"EOF" > /etc/systemd/system/courier-mta.service.d/restart-always.conf
[Service]
# courier-mta.service is a mixture of courierd, esmtpd and *esmtpd-msa
PIDFile=/run/courier/esmtpd-msa.pid
RemainAfterExit=no
Restart=always
EOF

# Restart script
Dinstall mail/courier-restart.sh

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
#     nobody: postmaster
#     postmaster: |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS admin@szepe.net

# Listen on 587 and 465 and allow only authenticated clients even without PTR record
editor /etc/courier/esmtpd
#     NOADDRREWRITE=2
#     ADDRESS=127.0.0.1
#     BLACKLISTS="-block=bl.blocklist.de"
#     TCPDOPTS+="-noidentlookup -nodnslookup"
#     ESMTPAUTH=""
#     ESMTPAUTH_TLS="PLAIN LOGIN"
editor /etc/courier/esmtpd-msa
#     NOADDRREWRITE=2
#     AUTH_REQUIRED=1
#     ADDRESS=0
#     ESMTPDSTART=YES
editor /etc/courier/esmtpd-ssl
#     NOADDRREWRITE=2
#     BLACKLISTS="-block=bl.blocklist.de"
#     AUTH_REQUIRED=1
#     SSLADDRESS=0

# 1 day queue time
echo "1d" > /etc/courier/queuetime

# Infrequent restarts
echo "23h" > /etc/courier/respawnlo

# *Announce* message size limit
echo "$((25 * 1024**2))" > /etc/courier/sizelimit

# SSL configuration
# https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=apache-2.4.14&openssl=1.0.1k&hsts=yes&profile=intermediate
editor /etc/courier/courierd
editor /etc/courier/esmtpd
editor /etc/courier/esmtpd-ssl
#     @TODO Modern, Intermediate ciphers
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
#
#     TLS_COMPRESSION=NULL
#     TLS_DHPARAMS=/etc/courier/dhparams.pem
#     TLS_CACHEFILE=/var/lib/courier/couriersslcache
#     TLS_CACHESIZE=524288

# Diffie-Hellman parameters
rm -f /etc/courier/dhparams.pem
DH_BITS=medium nice /usr/sbin/mkdhparams
# DH params cron job
( cd ${D}; ./install.sh mail/courier-dhparams.sh )

# Let's Encrypt certificate by manuale
# See /security/LetsEncrypt.md and use /security/cert-update-manuale-CN.sh
touch /etc/courier/esmtpd.pem
chmod 0600 /etc/courier/esmtpd.pem
Dinstall monitoring/cert-expiry.sh

# ClamAV + no_received_headers
apt-get install -y python2.7 clamav-daemon uuid-runtime
freshclam -v
wget -P /root/dist-mod/ http://ftp.de.debian.org/debian/pool/main/p/pyclamd/python-pyclamd_0.3.16-1_all.deb
dpkg -i /root/dist-mod/python-pyclamd_*_all.deb
wget -qO- https://bootstrap.pypa.io/get-pip.py | python2
# courierfilter -> pythonfilter/clamav.py -> pyclamd -> clamd socket -> clamd -> scan in /var/lib/courier/tmp
# Not since v0.99.2 sed -i -e 's/^AllowSupplementaryGroups\s.*/AllowSupplementaryGroups true/' /etc/clamav/clamd.conf
adduser clamav daemon
# Install pythonfilter
# Alternative: http://www.tana.it/sw/avfilter/
pip2 -v install "https://bitbucket.org/gordonmessmer/courier-pythonfilter/get/default.tar.gz"
cat > /etc/pythonfilter.conf <<EOF
clamav
attachments
noreceivedheaders
EOF
cat > /etc/pythonfilter-modules.conf <<EOF
[clamav.py]
localSocket = '/run/clamav/clamd.ctl'
action = 'quarantine'

[Quarantine]
siteid = '$(uuidgen)'
dir = '/var/lib/pythonfilter/quarantine'
days = 14
EOF
# Quarantine
mkdir -p /var/lib/pythonfilter/quarantine
chown -cR daemon:daemon /var/lib/pythonfilter
# Enable pythonfilter
ln -vs /usr/local/bin/pythonfilter /usr/lib/courier/filters/
filterctl start pythonfilter; ls -l /etc/courier/filters/active

# SRS (Sender Rewriting Scheme)
apt-get install -y couriersrs
couriersrs -v
install -b -o root -g daemon -m 640 /dev/null /etc/srs_secret
apg -a 1 -M LCNS -m 30 -n 1 > /etc/srs_secret
# Create system aliases SRS0 and SRS1
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS0-default
echo "|/usr/bin/couriersrs --reverse" > /etc/courier/aliasdir/.courier-SRS1-default
# SRS domain cannot be a virtual domain
#     # @virt.dom: an@account.net
# Add forwarding alias
#     user:  |/usr/bin/couriersrs --srsdomain=DOMAIN.SRS username@external-domain.tld

# Accounts
mkdir /etc/courier/esmtpacceptmailfor.dir
makeacceptmailfor
install -b -o root -g root -m 644 /dev/null /etc/courier/hosteddomains
makehosteddomains
editor /etc/courier/authdaemonrc
#     authmodulelist="authuserdb"
install -b -o root -g root -m 600 /dev/null /etc/courier/userdb
makeuserdb

# Restart Courier MTA
courier-restart.sh

# Test
echo "This is a t3st mail." | mail -s "[$(hostname -f)] The 1st outgoing mail" admin@szepe.net
#tail -f /var/log/syslog
journalctl -f

# Monitoring
# SystemV
Dinstall monitor/syslog-errors-infrequent.sh
# Don't suppress Courier MTA SSL errors as they may come from authorized clients!
# Systemd
apt-get install -y libpam-systemd
mkdir ${HOME}/.config/systemd
cd ${HOME}/.config/systemd/
git clone https://github.com/kylemanna/systemd-utils.git "utils"
cp ./utils/failure-monitor/failure-monitor@.service /etc/systemd/user/
systemctl --user enable "failure-monitor@postmaster@szepe.net.service"
systemctl --user start "failure-monitor@postmaster@szepe.net.service"

# User accounts for sending mail
# /mail/add-mailaccount.sh USER@DOMAIN
