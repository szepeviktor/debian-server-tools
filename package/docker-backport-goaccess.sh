#!/bin/bash
#
# Build goaccess package from Debian sources.
#
# DEPENDS       :docker pull szepeviktor/stretch-backport

set -e

test -d /opt/results || mkdir /opt/results

# Pre-deps hook ----------
cat <<"EOF" > /opt/results/debackport-pre-deps
# Enable ncurses wide characters support and mmdb support
sed -i -e '0,/libncurses5-dev,/s||libncursesw5-dev, libmaxminddb-dev,|' ./debian/control
# Enable UTF-8 and mmdb
sed -i -e 's|^\s*dh_auto_configure\s.*|\tdh_auto_configure -- --enable-utf8 --enable-geoip=mmdb --enable-tcb=btree|' ./debian/rules
# Raise MAX_IGNORE_IPS = 1024 + 128
cat <<"EOT" | base64 -d > ./debian/patches/9999-max-ignore-ips.patch
RnJvbTogVmlrdG9yIFN6w6lwZSA8dmlrdG9yQHN6ZXBlLm5ldD4KRGF0ZTogTW9uLCAwOCBKYW4g
MjAxOCAxNTozMToxMyArMDAwMApTdWJqZWN0OiBTZXQgTUFYX0lHTk9SRV9JUFMgdG8gMTE1MgoK
QWxyZWFkeSBpbiB1cHN0cmVhbTogaHR0cHM6Ly9naXRodWIuY29tL2FsbGludXJsL2dvYWNjZXNz
L2NvbW1pdC80YmJlNzNkYzlkZTE1MzNlMjlkYTBiMTg0MjRkZDE3OWMyYjk4NGYxCi0tLQogc3Jj
L3NldHRpbmdzLmguYyB8IDIgKy0KIDEgZmlsZSBjaGFuZ2VkLCAxIGluc2VydGlvbnMoKyksIDEg
ZGVsZXRpb25zKC0pCgpkaWZmIC0tZ2l0IGEvc3JjL3NldHRpbmdzLmggYi9zcmMvc2V0dGluZ3Mu
aAppbmRleCA2YzZjZDRmLi40MjhmMWJmIDEwMDY0NAotLS0gYS9zcmMvc2V0dGluZ3MuaAorKysg
Yi9zcmMvc2V0dGluZ3MuaApAQCAtMzUsNyArMzUsNyBAQAogCiAjZGVmaW5lIE1BWF9MSU5FX0NP
TkYgICAgIDUxMgogI2RlZmluZSBNQVhfRVhURU5TSU9OUyAgICAxMjgKLSNkZWZpbmUgTUFYX0lH
Tk9SRV9JUFMgICAgIDY0CisjZGVmaW5lIE1BWF9JR05PUkVfSVBTICAgMTE1MgogI2RlZmluZSBN
QVhfSUdOT1JFX1JFRiAgICAgNjQKICNkZWZpbmUgTUFYX0NVU1RPTV9DT0xPUlMgIDY0CiAjZGVm
aW5lIE1BWF9JR05PUkVfU1RBVFVTICA2NAo=
EOT

echo "9999-max-ignore-ips.patch" >> ./debian/patches/series
EOF

# Build it ----------
docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="goaccess/testing" szepeviktor/stretch-backport

rm /opt/results/debackport-pre-deps

echo "OK."
