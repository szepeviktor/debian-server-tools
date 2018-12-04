#!/bin/bash
#
# Create patch file of changes in config files by directory.
#
# VERSION       :0.1.1
# LOCATION      :/usr/local/bin/config-compare.sh

# Absolute path of configuration directory
CONFIGDIR="$1"

# Debian release
DIST="$(lsb_release --short --codename)"

EXTRACTDIR="./fsroot"
CONFIGDIR="${CONFIGDIR%/}"

# Must be existing absolute path
test "${CONFIGDIR:0:1}" == "/" || exit 1
test -d "$CONFIGDIR" || exit 2

# Download packages containing files in the configuration directory
dpkg -S "${CONFIGDIR}/*" \
    | sed -e 's/, /:\n/g' | cut -d ":" -f 1 \
    | sort -u \
    | xargs -r -L 1 apt-get -t "$DIST" download || exit 10

# Extract packages
find . -type f -name "*.deb" -printf '%P\n' \
    | xargs -I % dpkg-deb --extract % "$EXTRACTDIR" \
    || exit 11

# Create patch file
PATCH="$(basename "$CONFIGDIR")-config.patch"
diff -r -w -B "${EXTRACTDIR}${CONFIGDIR}" "$CONFIGDIR" >"$PATCH"
grep --color '^diff\|^Only' "$PATCH"
