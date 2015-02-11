
exit 0

# Courier-mta message processing order
# 1. SMTP communication
# 2. NOADD*, "opt MIME=none"
# 3. filters
# 4. DEFAULTDELIVERY

# gamin for courier-imap

# authmysqlrc
DEFAULT_DOMAIN  szepe.net
MYSQL_SERVER            localhost
MYSQL_PORT              0
MYSQL_DATABASE          horde
MYSQL_USERNAME          courier
MYSQL_USER_TABLE        courier_horde
MYSQL_PASSWORD          <PASSWORD>

MYSQL_AUXOPTIONS_FIELD  options
MYSQL_CHARACTER_SET     utf8
MYSQL_CRYPT_PWFIELD     crypt
MYSQL_DEFAULTDELIVERY   defaultdelivery
MYSQL_GID_FIELD         gid
MYSQL_HOME_FIELD        home
MYSQL_LOGIN_FIELD       id
MYSQL_MAILDIR_FIELD     maildir
MYSQL_NAME_FIELD        name
MYSQL_OPT               0
MYSQL_QUOTA_FIELD       quota
MYSQL_UID_FIELD         uid


# python filters (python3)
# lxml dependencies
apt-get install -y libxml2-dev libxslt-dev cython3
pip3 install lxml
pip3 install html2text
pip3 install courier-pythonfilter
# custom python filters
git clone https://github.com/szepeviktor/courier-pythonfilter-custom
# /usr/local/lib/python3.4 for jessie
ln -sv email-correct.py /usr/local/lib/python3.2/dist-packages/pythonfilter/
ln -sv spamassassin3.py /usr/local/lib/python3.2/dist-packages/pythonfilter/
# whitelist_replayclient dependency
apt-get install -y python3-gdbm
ln -sv /usr/local/bin/pythonfilter /usr/lib/courier/filters
filterctl start pythonfilter

# DKIM support
# build deps
#apt-get install -y -t wheezy-backports libopendkim-dev libopendbx1-dev nettle-dev
#apt-get install -y libc6-dev pkg-config libtool
# runtim deps
apt-get install -y libopendkim7
apt-get install -y -t wheezy-backports libopendbx1 libnettle4
# source
wget -O- http://www.tana.it/sw/zdkimfilter/ | tar xz
./configure && make check && make install

# Spamassassin
# trunk: http://svn.apache.org/repos/asf/spamassassin/trunk/
# DKIM check
apt-get install -y libmail-dkim-perl
# rule compile
mkdir -p /var/lib/spamassassin/compiled && chmod -R go-w,go+rX /var/lib/spamassassin/
#cd /etc/cron.hourly
#patch -p0 < spamassassin34.patch
pip3 install pyzor

# e /etc/courier/smtpaccess/default
# :::1<-->allow,RELAYCLIENT

# document message way SMTP, courier C, courier filters (spamassassin, pyzor), aliases, .courier

#TODO Where to whitelist: courier domain,IP; sa domain; dnsbl known_hosts;
#     What: own IP, servers, (smtp.timeweb.ru), broken SMTP servers
#     providers (ISP, bank, shared hosting, VPS, server, DNS, Incapsula/CloudFlare)
#     subscriptions, account (ifttt, linkedin, hubiC)
#     freemail?? (gmail, freemail, citromail, indamail)


# MISSING_MID monitoring

# maildrop: https://help.ubuntu.com/community/MailServerCourierSpamAssassin

# scores
#TODO add descriptions
score RDNS_NONE                  3.0 -> spamassassin3.py rejects
score RDNS_DYNAMIC               2.0
score DYN_RDNS_AND_INLINE_IMAGE  3.0
score DNS_FROM_RFC_BOGUSMX       4.0

score SPF_HELO_FAIL              2.0
score FM_FAKE_HELO_HOTMAIL       2.0

score T_DKIM_INVALID             1.0
whitelist_from *@domain.tld
# sagrey.pm

# Monitoring
# - MAIL_RECEPTION='courieresmtpd: error.*534 SIZE=Message too big\|courieresmtpd: error.*523 Message length .* exceeds administrative limit'
# - MAIL_FILER_EXCEPTION='courierfilter:.*xception'
# - MAIL_BROKEN='4[0-9][0-9]\s*tls\|Broken pipe'
# - weekly: grep "courieresmtpd: .*: 5[0-9][0-9] " "/var/log/mail.log.1" | grep -wv "554"
# - yearly: archive
# - monthly: maildir-top10-message-count & -folder-size (du -sk "$FULLPATH")
