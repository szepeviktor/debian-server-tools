#!/bin/bash
#
# Create patch file of changes in config files by directory.
#
# VERSION       :0.1.0
# DEPENDS       :apt-get install aptitude
# LOCATION      :/usr/local/bin/config-compare.sh

# Absolute path of configuration directory
CONFIGDIR="$1"

# Name of your release
#DIST="jessie"
DIST="$(lsb_release --short --codename)"

EXTRACTDIR="./fsroot"
CONFIGDIR="${CONFIGDIR%/}"

# Must be existing absolute path
[ "${CONFIGDIR:0:1}" == "/" ] || exit 1
[ -d "$CONFIGDIR" ] || exit 2

# Download packages containing files in the configuration directory
dpkg -S "${CONFIGDIR}/*" \
    | sed 's/, /:\n/g' | cut -d ":" -f 1 \
    | sort | uniq \
    | xargs -r -L 1 aptitude -t "$DIST" download || exit 10

# Extract packages
ls *.deb | xargs -I %% dpkg-deb --extract %% "$EXTRACTDIR" || exit 11

# Create patch file
PATCH="$(basename "$CONFIGDIR")-config.patch"
diff -rwB "${EXTRACTDIR}${CONFIGDIR}" "$CONFIGDIR" > "$PATCH"
grep --color "^diff\|^Only" "$PATCH"
