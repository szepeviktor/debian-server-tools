
exit 0

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
