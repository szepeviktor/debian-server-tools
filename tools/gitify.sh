#!/bin/bash
#
# Turn release tar files into a git repository.
#

VERSION_CMD='for VERSION in $(seq 0 11); do echo "1.${VERSION}"; done'
URL_TPL='http://phantom.dragonsdawn.net/~gordon/courier-pythonfilter/courier-pythonfilter-%s.tar.gz'
EXTRACT_CMD='tar -xz --strip-components=1'

set -e

# Run it from the git dir as ../gitify.sh
! [ -f ./gitify.sh ]

eval "$VERSION_CMD" \
    | while read -r VER; do
        git rm -qrf * || true
        wget -nv -O- "$(printf "$URL_TPL" "$VER")" | eval "$EXTRACT_CMD"
        git add --all
        git commit -m "Version ${VER}"
    done
