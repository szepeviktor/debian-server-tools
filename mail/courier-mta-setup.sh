
exit 0

# Courier-mta message processing order
# 1. SMTP communication
# 2. NOADD*, "opt MIME=none"
# 3. filters
# 4. DEFAULTDELIVERY


# python filter
# lxml dependencies
apt-get install -y libxml2-dev libxslt-dev cython
pip install lxml
pip install html5lib
pip install html2text
pip install courier-pythonfilter
# custom python filters
git clone https://github.com/szepeviktor/courier-pythonfilter-custom
ln -sv email-correct.py /usr/local/lib/python2.7/dist-packages/pythonfilter/
ln -sv spamassassin3.py /usr/local/lib/python2.7/dist-packages/pythonfilter/

# DKIM support
# build deps
apt-get install -y -t wheezy-backports libopendkim-dev libopendbx1-dev nettle-dev
apt-get install -y libc6-dev pkg-config libtool
# runtim deps
apt-get install -y libopendkim7
apt-get install -y -t wheezy-backports libopendbx1 libnettle4
# source
wget -O- http://www.tana.it/sw/zdkimfilter/ | tar xz
./configure && make check && make install

#
# rule compile:
mkdir -p /var/lib/spamassassin/compiled && chmod -R go-w,go+rX /var/lib/spamassassin/
# DKIM check:
apt-get install -y libmail-dkim-perl

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
