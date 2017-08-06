#!/bin/bash
#
# Build goaccess package from Debian sources.
#
# DEPENDS       :docker pull szepeviktor/jessie-backport

[ -d /opt/results ] || mkdir /opt/results

# Init hook ----------
cat <<"EOF" > /opt/results/debackport-init
echo "deb http://deb.debian.org/debian jessie-backports main" \
    | sudo tee -a /etc/apt/sources.list
sudo apt-get update -qq
sudo apt-get install -qq python3-xstatic-hogan
EOF

# Pre-deps hook ----------
cat <<"EOF" > /opt/results/debackport-pre-deps
# Enable UTF-8
sed -i -e 's|^\s*dh_auto_configure\s.*|\tdh_auto_configure -- --enable-utf8 --enable-geoip=legacy --enable-tcb=btree|' ./debian/rules
# Fix and add libncursesw5-dev
sed -i -e '0,/libncurses5-dev,/s||libncursesw5-dev,|' ./debian/control
# Raise MAX_IGNORE_IPS = 1024 + 128
cat <<"BASE64" | base64 -d > ./debian/patches/9999-max-ignore-ips-1152.patch
RGVzY3JpcHRpb246IE1BWF9JR05PUkVfSVBTID0gMTE1MgogLgogZ29hY2Nlc3MgKDE6MS4yLTMp
IHVuc3RhYmxlOyB1cmdlbmN5PW1lZGl1bQogLgogICAqIGRlYmlhbi9nZW4tYnVpbHQtdXNpbmc6
IGxpc3Qgc291cmNlIHBhY2thZ2VzIGluc3RlYWQgb2YgYmluYXJpZXMKICAgICAoQ2xvc2VzOiAj
ODY0OTI4KQogICAqIEJ1bXAgU3RhbmRhcmRzLVZlcnNpb246IHRvIDMuOS44OyBubyBjaGFuZ2Vz
IG5lZWRlZCBvdGhlcndpc2UKICAgKiBCdW1wIGRlYmhlbHBlciBjb21wYXRpYmlsaXR5IGxldmVs
IHRvIDEwCkF1dGhvcjogQW50b25pbyBUZXJjZWlybyA8dGVyY2Vpcm9AZGViaWFuLm9yZz4KQnVn
LURlYmlhbjogaHR0cHM6Ly9idWdzLmRlYmlhbi5vcmcvODY0OTI4CgotLS0KTGFzdC1VcGRhdGU6
IDwyMDE3LTA4LTA2PgoKLS0tIGdvYWNjZXNzLTEuMi5vcmlnL3NyYy9zZXR0aW5ncy5oCisrKyBn
b2FjY2Vzcy0xLjIvc3JjL3NldHRpbmdzLmgKQEAgLTM1LDcgKzM1LDcgQEAKIAogI2RlZmluZSBN
QVhfTElORV9DT05GICAgICA1MTIKICNkZWZpbmUgTUFYX0VYVEVOU0lPTlMgICAgMTI4Ci0jZGVm
aW5lIE1BWF9JR05PUkVfSVBTICAgICA2NAorI2RlZmluZSBNQVhfSUdOT1JFX0lQUyAgIDExNTIK
ICNkZWZpbmUgTUFYX0lHTk9SRV9SRUYgICAgIDY0CiAjZGVmaW5lIE1BWF9DVVNUT01fQ09MT1JT
ICA2NAogI2RlZmluZSBNQVhfSUdOT1JFX1NUQVRVUyAgNjQK
BASE64
echo "9999-max-ignore-ips-1152.patch" >> ./debian/patches/series
EOF

# Build it ----------
docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="goaccess/testing" szepeviktor/jessie-backport
rm -f /opt/results/debackport-{init,pre-deps}
