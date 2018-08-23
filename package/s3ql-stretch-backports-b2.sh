#!/bin/bash
#
# Build s3ql Debian package with support for BackBlaze B2.
#
# https://github.com/sylvainlehmann/s3ql/commits/master

set -e

# Patch is compatible with S3QL up to v2.26
dget -ux "http://http.debian.net/debian/pool/main/s/s3ql/s3ql_2.21+dfsg-3.dsc"
rm -v s3ql_*.debian.tar.xz s3ql_*.dsc s3ql_*.orig.tar.*
wget "https://github.com/s3ql/s3ql/pull/8.patch"

cd s3ql-*/

# BackBlaze B2 patch
patch -p 1 < ../8.patch

# debian/changelog
B2_TEMP="$(mktemp)"
cat - debian/changelog >"$B2_TEMP" <<"EOF"
s3ql (2.21+dfsg-4) stretch; urgency=medium

  * Rebuild for stretch with support for BackBlaze B2
    https://github.com/s3ql/s3ql/pull/8

 -- Viktor Szépe <viktor@szepe.net>  Thu, 23 Aug 2018 10:41:12 +0000

EOF

mv "$B2_TEMP" debian/changelog

# Dependencies
dpkg-checkbuilddeps 2>&1 | cut -d ":" -f 4- \
    | tr ' ' '\n' | grep -v '[)(]' | uniq \
    | xargs -t apt-get install -y

# Build it
dpkg-buildpackage -uc -us -B
echo "OK."
