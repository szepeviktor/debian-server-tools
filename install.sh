#!/bin/bash
#
# Install all tools from debian-server-tools.
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+


die() {
    local RET="$1"
    shift
    echo -e $@ >&2
    exit "$RET"
}

#####################################################
# Parses out the version from a script
# Arguments:
#   FILE
#####################################################
get_version() {
    local FILE="$1"
    local VER="$(grep -m1 "^# VERSION\s*:" "$FILE" | cut -d":" -f2-)"

    if [ -z "$VER" ]; then
        VER="(unknown)"
    fi
    echo "$VER"
}

#####################################################
# Copies files in place, sets permissions and owner
# Arguments:
#   LOCATION
#   OWNER
#   PERMS
#   <file> <file> ...
#####################################################
do_install() {
    local LOCATION="$1"
    local OWNER="$2"
    local PERMS="$3"
    local TARGET

    shift 3

    for TOOL in $@; do
        TARGET="${LOCATION}/$(basename "$TOOL")"
        if [ -f "$TARGET" ]; then
            echo -n "replacing $(get_version "$TARGET") with $(get_version "$TOOL") "
        fi

        cp -v "$TOOL" "$TARGET" || die 10 "copy failure (${TOOL})"
        chown ${OWNER} "$TARGET" || die 11 "cannot set owner (${TOOL})"
        chmod ${PERMS} "$TARGET" || die 12 "cannot set permissions (${TOOL})"
    done
}

#########################################################

[ "$(id --user)" = 0 ] || die 1 "only root is allowed to install"

# version
if [ "$1" = "--version" ]; then
    get_version "$0"
    exit 0
fi

echo "debian-server-tools installer"

# system binaries
do_install /usr/local/sbin root:root 755 \
    monitoring/package-versions.sh


