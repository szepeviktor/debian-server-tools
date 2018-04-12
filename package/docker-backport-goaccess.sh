#!/bin/bash
#
# Build goaccess package from Debian sources.
#
# DEPENDS       :docker pull szepeviktor/stretch-backport

set -e

test -d /opt/results || mkdir /opt/results

# Pre-deps hook
cat <<"EOF" > /opt/results/debackport-pre-deps
# Enable ncurses wide characters support and mmdb support
sed -e '0,/libncurses5-dev,/s||libncursesw5-dev, libmaxminddb-dev,|' -i ./debian/control
# Enable UTF-8 and mmdb
sed -e 's|^\s*dh_auto_configure\s.*|\tdh_auto_configure -- --enable-utf8 --enable-geoip=mmdb --enable-tcb=btree|' -i ./debian/rules
# Raise MAX_IGNORE_IPS = 2048
cat <<"EOT" | base64 -d > ./debian/patches/9999-max-ignore-ips.patch
RnJvbTogVmlrdG9yIFN6w6lwZSA8dmlrdG9yQHN6ZXBlLm5ldD4KRGF0ZTogTW9uLCAwOSBBcHIg
MjAxOCAyMToxMzoyOCArMDAwMApTdWJqZWN0OiBTZXQgTUFYX0lHTk9SRV9JUFMgdG8gMjA0OAoK
MTAyNCArIDEyOCBpbiB1cHN0cmVhbTogaHR0cHM6Ly9naXRodWIuY29tL2FsbGludXJsL2dvYWNj
ZXNzL2NvbW1pdC80YmJlNzNkYzlkZTE1MzNlMjlkYTBiMTg0MjRkZDE3OWMyYjk4NGYxCi0tLQog
c3JjL3NldHRpbmdzLmguYyB8IDIgKy0KIDEgZmlsZSBjaGFuZ2VkLCAxIGluc2VydGlvbnMoKyks
IDEgZGVsZXRpb25zKC0pCgpkaWZmIC0tZ2l0IGEvc3JjL3NldHRpbmdzLmggYi9zcmMvc2V0dGlu
Z3MuaAppbmRleCA2YzZjZDRmLi40MjhmMWJmIDEwMDY0NAotLS0gYS9zcmMvc2V0dGluZ3MuaAor
KysgYi9zcmMvc2V0dGluZ3MuaApAQCAtMzUsNyArMzUsNyBAQAogCiAjZGVmaW5lIE1BWF9MSU5F
X0NPTkYgICAgIDUxMgogI2RlZmluZSBNQVhfRVhURU5TSU9OUyAgICAxMjgKLSNkZWZpbmUgTUFY
X0lHTk9SRV9JUFMgICAgIDY0CisjZGVmaW5lIE1BWF9JR05PUkVfSVBTICAgMjA0OAogI2RlZmlu
ZSBNQVhfSUdOT1JFX1JFRiAgICAgNjQKICNkZWZpbmUgTUFYX0NVU1RPTV9DT0xPUlMgIDY0CiAj
ZGVmaW5lIE1BWF9JR05PUkVfU1RBVFVTICA2NAo=
EOT

echo "9999-max-ignore-ips.patch" >> ./debian/patches/series
EOF

# Build it
docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="goaccess/testing" szepeviktor/stretch-backport

rm /opt/results/debackport-pre-deps

echo "OK."
