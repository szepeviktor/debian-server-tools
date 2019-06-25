#!/bin/bash
#
# Source: http://svn.apache.org/repos/asf/spamassassin/trunk/
# maildrop: https://help.ubuntu.com/community/MailServerCourierSpamAssassin
#
# Rule updating process
#
# 1. SVN revision lookup by reverse version number
#     host -t TXT 1.4.3.updates.spamassassin.org.
# 2. Get mirror URL
#     wget https://svn.apache.org/repos/asf/spamassassin/site/updates/MIRRORED.BY
# 3. Download rules
#     wget ${MIRROR_URL}/${SVN_REVISION}.tar.gz
# 4. Current local version
#     head -n 1 /var/lib/spamassassin/3.*/updates_spamassassin_org.cf

# @TODO MISSING_MID monitoring cron job

set -e -x

# Install from stable and also install dependencies and recommended packages
apt-get install -y libmail-spf-perl pyzor spamassassin
# Already a dependency: libmail-dkim-perl

# Upgrade to latest version
Getpkg spamassassin
Getpkg spamc

# Enable spamassassin
sed -e 's|^ENABLED=.*$|ENABLED=1|' -e 's|^CRON=.*$|CRON=1|' -i /etc/default/spamassassin
# Only 'courier' user will use spamassassin
# HOME=/var/lib/courier
# man spamd
sed -e 's|^OPTIONS=.*$|OPTIONS="--create-prefs --max-children 5 --helper-home-dir --allow-tell --nouser-config --virtual-config-dir=/var/lib/courier/.spamassassin --username=courier --groupname=courier"|' -i /etc/default/spamassassin

# v320.pre
# Enable Shortcircuit plugin
sed -e 's|^# \(loadplugin Mail::SpamAssassin::Plugin::Shortcircuit\)$|\1|' -i /etc/spamassassin/v320.pre

# 65_debian.cf
# Use bb.barracudacentral.org
Dinstall mail/spam/66_barracudacentral.cf

# local.cf
Dinstall mail/spam/local.cf

# mail/spam/*.cf
Dinstall mail/spam/10_freemail_undisclosed.cf
Dinstall mail/spam/10_rare_tld.cf
Dinstall mail/spam/20_lashback.cf
Dinstall mail/spam/20_ibm.cf
#Dinstall mail/spam/20_junkemailfilter.cf
Dinstall mail/spam/20_spamrats_spam.cf

# spammer.dnsbl
Dinstall mail/spammer.dnsbl/20_spammer.dnsbl.cf
