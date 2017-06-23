#!/bin/bash
#
# Build s3ql-2.21 Debian package with support for BackBlaze B2.
#
# https://github.com/sylvainlehmann/s3ql/commits/master

dget -ux "http://http.debian.net/debian/pool/main/s/s3ql/s3ql_2.21+dfsg-1~bpo8+1.dsc"
rm -v s3ql_2.21+dfsg-1~bpo8+1.debian.tar.xz s3ql_2.21+dfsg-1~bpo8+1.dsc s3ql_2.21+dfsg.orig.tar.xz
wget "https://github.com/sylvainlehmann/s3ql/compare/2a074fe7a1db2b495e5fa320e339aa9e1f676b8c...effc70f0e81e3a5c6d465e02f5f018ac1ab55764.patch"

cd s3ql-2.21+dfsg/

# B2 patch
patch -p1 < ../2a074fe7a1db2b495e5fa320e339aa9e1f676b8c...effc70f0e81e3a5c6d465e02f5f018ac1ab55764.patch

# debian/changelog
B2_TEMP="$(mktemp)"
cat - debian/changelog > "$B2_TEMP" <<"EOF"
s3ql (2.21+dfsg-1~bpo8+2) jessie-backports; urgency=medium

  * Rebuild for jessie-backports with support for BackBlaze B2
    https://github.com/sylvainlehmann/s3ql/compare/2a074fe7a1db2b495e5fa320e339aa9e1f676b8c...effc70f0e81e3a5c6d465e02f5f018ac1ab55764.patch

 -- Nikolaus Rath <Nikolaus@rath.org>  Wed, 19 Apr 2017 23:56:59 +0000

EOF
mv "$B2_TEMP" debian/changelog

# Dependencies
dpkg-checkbuilddeps 2>&1 | cut -d: -f3- \
    | tr ' ' '\n' | grep -v "[()]" | uniq \
    | grep -Ex "(cython3|python3-(setuptools|pkg-resources|pytest-catchlog|pytest|dugong|requests|llfuse-dbg|llfuse))" \
    | xargs apt-get install -t jessie-backports -y
dpkg-checkbuilddeps 2>&1 | cut -d: -f3- \
    | tr ' ' '\n' | grep -v "[()]" | uniq \
    | grep -vEx "(cython3|python3-(setuptools|pkg-resources|pytest-catchlog|pytest|dugong|requests|llfuse-dbg|llfuse))" \
    | xargs apt-get install -y

# Build it
dpkg-buildpackage -uc -us -B
