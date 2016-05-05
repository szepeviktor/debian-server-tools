#!/bin/bash --version
#
# Courier MTA receive-only configuration with accounts.
#

# Locally generated mail (sendmail, SMTP, notifications)
#     MTA <-- sendmail (local monitoring scripts)
#     MTA <-- DSN
#
# Receiving from foreign hosts (inbound SMTP, SMTP-MSA)
#     MTA <-- Internet
#
# Delivering to 'smarthosts' or transactional email providers (outbound SMTP)
#     MTA --> smarthosts
#     MTA --> transactional providers
#
# Forward to a foreign mailbox (SRS)
#     MTA --> another MTA
#
# Delivering to local mailboxes (accounts)
#     MTA --> MDA
#
# Fetching remote mailboxes (fetchmail)
#     MDA <-- remote MDA
#
# Reading mail in local mailboxes (IMAP)
#     MUA <-- MDA


# RECEIVING (esmtpd)
#
# - transport: SMTP, SMTP STARTTLS, SMTP-MSA STARTTLS, SMTPS
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
# - IMAP folder names, IMAP_EMPTYTRASH=Trash:0
# - SSL cert, settings
#
# MONITORING
#
# - MAIL_RECEPTION='courieresmtpd: error.*534 SIZE=Message too big\|courieresmtpd: error.*523 Message length .* exceeds administrative limit'
# - MAIL_FILER_EXCEPTION='courierfilter:.*xception'
# - MAIL_BROKEN='4[0-9][0-9]\s*tls\|Broken pipe'
# - weekly: grep "courieresmtpd: .*: 5[0-9][0-9] " "/var/log/mail.log.1" | grep -wv "554"
# - monthly: top10-mailfolders.sh
# - yearly: archive inbox and sent folders

exit 0

# Courier MTA setup
# @TODO Common parts with courier-mta-satellite-system.sh

# Testing: Fail2ban addignoreip && TCPDOPTS += -noidentlookup -nodnslookup

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

# @TODO Well-known and autodiscover

# BLACKLISTS="-block=bl.blocklist.de"
