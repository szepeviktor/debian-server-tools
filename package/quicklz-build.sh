#!/bin/bash
#
# Get and build qzip.
#

# Usage with tar
#
#     qtar: `tar -I /usr/bin/qzip "$@"`

# Get sources
wget -nv -N -i - <<EOF
http://www.quicklz.com/quicklz.h
http://www.quicklz.com/quicklz.c
http://www.quicklz.com/manual.html
http://www.quicklz.com/compress_file.c
http://www.quicklz.com/decompress_file.c
http://www.quicklz.com/stream_compress.c
http://www.quicklz.com/stream_decompress.c
http://www.quicklz.com/qzip.tar
EOF

# Unpack
tar xvf qzip.tar Makefile qzip.c
chmod -x Makefile qzip.c

# Set QLZ_STREAMING_BUFFER = 100000
sed -i 's|#define QLZ_STREAMING_BUFFER 0$|//#define QLZ_STREAMING_BUFFER 0|' quicklz.h
sed -i 's|//#define QLZ_STREAMING_BUFFER 100000$|#define QLZ_STREAMING_BUFFER 100000|' quicklz.h

# Set QLZ_COMPRESSION_LEVEL = 1
sed -i 's|#define QLZ_COMPRESSION_LEVEL 1$|//#define QLZ_COMPRESSION_LEVEL 1|' quicklz.h
sed -i 's|//#define QLZ_COMPRESSION_LEVEL 3$|#define QLZ_COMPRESSION_LEVEL 3|' quicklz.h

# Patch for `tar -I qzip` usage
cat <<EOF | base64 -d | xz -d | patch --verbose -p0
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4ALiATldABboBA4no1Ws7eVIziXA7pp7SJotzcClY74Xo1hfL8C2h0j+b9w
Z4I57I1MD5n7YEdOff5hOBriWFGsXRj4Esx5az+D6DtVRAdtePeJX8U+LDOz8U7KJhStV0/lhROmjEewAR+NoowlgcD
/fC6JWvX84cwFcLg/DieSVcZq7JknTI5ZWflKHCxvIsQsaYRZ2pqFAIl1N1QR5In279gvtLHihgdFvRctbr0/lk7+cC
kRWxiWlbGLbXLN5sN9f7qUbN3NDMxIzuMxHLGQ8FH8eIcKZ9aN0gFvKcsGheT5ec4fsFt9JQbp27U93Q7ql21F54q15
WA7iLa39aPph5pzmqRR0FjSu38UGUFayduDhqNpKBLiQbgQBGKC8ZBpUk3RSWgvCXIIfUck+EuoOoA5OsBkCzOPMWU7
kDQAAAAAA3OQsD3aIFt0AAdUC4wUAABwmZzmxxGf7AgAAAAAEWVo=
EOF

if which pandoc &> /dev/null; then
    pandoc -f html -t man manual.html > qzip.1.man
fi

# Build
make
