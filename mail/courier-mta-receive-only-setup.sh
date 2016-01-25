
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
#     - SSL certificate, settings
# - whitelisting: skip Spamassassin tests, whitelist_block.py
#     - relay clients (send-only servers using this host as a smarthost, whitelist_relayclients.py)
#     - managed hosts
#   / - incoming forwarded mail (upcmail, gmail, freemail, citromail, indamail)
#   | - providers (monitoring, shared/VPS/server hosting, object storage, DNS, WAF/proxy, CDN, ISP, bank)
#   | - other subscriptions (mailing lists, forums, trials)
#    \__> keepass
#     - broken SMTP servers (missing PTR, invalid MAIL FROM: etc.)
#     - extra cases (can-send-email, timeweb.ru relay)
#     - hosts with broken STARTTLS (advertised but unavailable, in esmtproutes `/SECURITY=NONE`)
# - blacklisting
#     - courier-pythonfilter filters
#     - spamassassin, RBL-s, multi.uribl.com DNS
#     - pyzor
#     - Fail2ban
#     - BIG-mail spammers
#     - AUTH attackers
#     How??? 1. reverse DNS hostname (PTR record),  2. From address (bofh)  3. Envelop sender (MAIL FROM:)
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
# - yearly: archive inbox and sent folders
# - monthly: top10-mailfolders.sh

# Courier MTA setup
# See: ${D}/debian-setup.sh

# courier-pythonfilter
#     /usr/local/lib/python2.7/dist-packages/pythonfilter
apt-get install -y python-gdbm
pip2 -v install courier-pythonfilter
grep -E "^(MAILUSER|MAILGROUP)\s*=" /etc/courier/esmtpd # "daemon"
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

