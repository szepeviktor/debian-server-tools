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
        cp -v "$TOOL" "$TARGET" || die 10 "copy failure (${TOOL})"
        chown ${OWNER} "$TARGET" || die 11 "cannot set owner (${TOOL})"
        chmod ${PERMS} "$TARGET" || die 12 "cannot set permissions (${TOOL})"
    done
}

#########################################################

[ "$(id --user)" = 0 ] || die 1 "only root is allowed to install"

# version
if [ "$1" = "--version" ]; then
    grep -m1 "^# VERSION\s*:" "$0" | cut -d":" -f2-
    exit 0
fi

echo "debian-server-tools installer"

# system binaries
do_install /usr/local/sbin root:root 755 \
    monitoring/package-versions.sh


