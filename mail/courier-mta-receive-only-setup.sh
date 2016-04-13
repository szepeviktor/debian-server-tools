#!/bin/bash --version

exit 0

# SENDING (through transactional email provider)
#
# - Mailjet SMTP/STARTTLS
#     https://github.com/szepeviktor/debian-server-tools/blob/master/mail/README.md#transactional-email-providers
#
# RECEIVING (esmtpd)
#
# - transport: SMTP, SMTP-TLS, SMTP-MSA, SMTPS
#     - SMTP AUTH methods (CRAM-* needs clear passwords)
#     - SSL certificate and settings
# - whitelisting: skip Spamassassin tests, whitelist_block.py
#     - relay clients (send-only servers using this host as a smarthost, whitelist_relayclients.py)
#     - managed hosts
#     - keepass-> incoming forwarded mail (upcmail, telekom, gmail, freemail, citromail, indamail)
#     - keepass-> providers (monitoring, shared/VPS/server hosting, object storage, DNS, WAF/proxy, CDN, ISP)
#     - keepass-> other subscriptions (banks, mailing lists, forums, trials)
#     - broken SMTP servers (missing PTR, invalid MAIL FROM: etc.)
#     - extra cases (can-send-email hosts, timeweb.ru relay)
#     - hosts with broken STARTTLS (advertised but unavailable, in esmtproutes `/SECURITY=NONE`)
# - blacklisting
#     - courier-pythonfilter filters
#     - spamassassin, RBL-s, DNs server for multi.uribl.com
#     - pyzor
#     - Fail2ban
#     - BIG-mail spammers
#     - AUTH attackers
#     How to blacklist??? 1. reverse DNS hostname(PTR record) ?,  2. From address: bofh  3. Envelop sender:(MAIL FROM:) ?
# - fetchmail
#
# READING MAIL (imapd)
#
# - authmodulelist="..."
# - IMAP AUTH methods
# - SSL cert, settings
# - IMAP folder names, IMAP_EMPTYTRASH=Trash:0
#
# MONITORING
#
# - MAIL_RECEPTION='courieresmtpd: error.*534 SIZE=Message too big\|courieresmtpd: error.*523 Message length .* exceeds administrative limit'
# - MAIL_FILER_EXCEPTION='courierfilter:.*xception'
# - MAIL_BROKEN='4[0-9][0-9]\s*tls\|Broken pipe'
# - weekly: grep "courieresmtpd: .*: 5[0-9][0-9] " "/var/log/mail.log.1" | grep -wv "554"
# - monthly: top10-mailfolders.sh
# - yearly: archive inbox and sent folders

# Courier MTA setup
# See: ${D}/debian-setup.sh

# SSL setup
# Testing: Fail2ban addignoreip && TCPDOPTS += -noidentlookup -nodnslookup
editor /etc/courier/esmtpd-ssl
editor /etc/courier/esmtpd
editor /etc/courier/esmtpd-msa # Only overrides esmtpd
editor /etc/courier/courierd
#     TLS_PROTOCOL="TLSv1.2:TLSv1.1:TLS1"
#     TLS_CIPHER_LIST="" See https://mozilla.github.io/server-side-tls/ssl-config-generator/
#     TLS_CERTFILE="/etc/courier/courier-comb3.pem"
#     TLS_DHPARAMS="/etc/courier/courier-dhparams.pem"
#     TLS_CACHEFILE=/var/lib/courier/tmp/ssl_cache
#     TLS_CACHESIZE=524288
#     # @TODO Enable session resumption (caching)

# courier-pythonfilter
#     /usr/local/lib/python2.7/dist-packages/pythonfilter
apt-get install -y python-gdbm
pip2 -v install courier-pythonfilter
grep -E "^(MAILUSER|MAILGROUP)\s*=" /etc/courier/esmtpd # == "daemon"
install -v --owner=daemon --group=daemon -d /var/lib/pythonfilter
ln -sv /usr/local/bin/pythonfilter /usr/lib/courier/filters/pythonfilter
filterctl start pythonfilter && readlink /etc/courier/filters/active/pythonfilter
editor /etc/pythonfilter.conf
#     modules/order???
editor /etc/pythonfilter-modules.conf

# DKIM signature
#     http://www.tana.it/sw/zdkimfilter/zdkimfilter.html
read -r -s -p "DKIM domain? " DOMAIN
apt-get install -y opendkim-tools zdkimfilter
cd /etc/courier/filters/
mkdir --mode=700 privs; chown -cR daemon:root privs/
cd privs/
opendkim-genkey -v --domain="${DOMAIN}" --selector="dkim$(date -u "+%m%d")"
cd ../; mkdir keys; cd keys/
ln -vs "../privs/dkim$(date -u "+%m%d").private" "${DOMAIN}"
editor zdkimfilter.conf
# http://www.linuxnetworks.de/doc/index.php/OpenDBX/Configuration#sqlite3_backend
touch zdkim.sqlite
chown -c daemon:root zdkim.sqlite; chmod -c 600 zdkim.sqlite
filterctl start zdkimfilter; ls -l /etc/courier/filters/active

# Tarbaby fake MX record
# http://wiki.junkemailfilter.com/index.php/Project_tarbaby
editor /etc/courier/smtpaccess/default
#     # https://tools.ietf.org/html/rfc2821#section-4.2.3
#     # https://tools.ietf.org/html/rfc3463#section-3.8
#     # http://www.iana.org/assignments/smtp-enhanced-status-codes/smtp-enhanced-status-codes.xhtml
#     *	allow,RELAYCLIENT,BLOCK="451 4.7.1 Please try another MX"

# Add lowest priority MX (highest numbered) record to DNS
domain.net.  IN  MX  50 tarbaby.domain.net.
