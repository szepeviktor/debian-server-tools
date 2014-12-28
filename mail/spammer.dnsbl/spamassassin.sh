
exit 0

# rule compile:
mkdir -p /var/lib/spamassassin/compiled && chmod -R go-w,go+rX /var/lib/spamassassin/
# DKIM check:
apt-get install -y libmail-dkim-perl
