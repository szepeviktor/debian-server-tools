#!/bin/bash
#
# Install all tools from debian-server-tools.
#
# VERSION       :0.3
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
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
    local VER="$(head -n30 "$FILE" | grep -m1 "^# VERSION\s*:" | cut -d":" -f2-)"

    if [ -z "$VER" ]; then
        VER="(unknown)"
    fi
    echo "$VER"
}

#####################################################
# Parses out LOCATION from a script
# Arguments:
#   FILE
#####################################################
get_location() {
    local FILE="$1"

    head -n30 "$FILE" | grep -m1 "^# LOCATION\s*:" | cut -d":" -f2
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

    # "go to" files
    shift 3

    # check location
    if ! [ -d "$LOCATION" ]; then
        # default owner (possibly root:root) and default permissions (755)
        echo "create directory: ${LOCATION}"
        mkdir -p "$LOCATION" || die 10 "cannot create dir (${LOCATION})"
    fi

    for TOOL in "$@"; do
        TARGET="${LOCATION}/$(basename "$TOOL")"
        echo "install: ${TARGET}"

        # check the file in place
        if ! diff "$TOOL" "$TARGET" &> /dev/null; then
            echo "${TOOL}: already up-to-date"
            continue
        fi

        # check for existence
        if [ -f "$TARGET" ]; then
            echo -n "replacing $(get_version "$TARGET") with $(get_version "$TOOL") "
        fi

        # copy and set owner and permissions
        cp -v "$TOOL" "$TARGET" || die 11 "copy failure (${TOOL})"
        chown --changes ${OWNER} "$TARGET" || die 12 "cannot set owner (${TOOL})"
        chmod --changes ${PERMS} "$TARGET" || die 13 "cannot set permissions (${TOOL})"
    done
}

#####################################################
# Process all files in a directory recursively
# Arguments:
#   DIR
#   OWNER
#   PERMS
#####################################################
do_dir() {
    local DIR="$1"
    local OWNER="$2"
    local PERMS="$3"
    local FILE
    local LOCATION

    find "$DIR" -type f \
        | while read FILE; do
            LOCATION="$(get_location "$FILE")"

            if ! [ -z "$LOCATION" ]; then
                # warn on different actual file name and file name in LOCATION
                if ! [ "$(basename "$FILE")" = "$(basename "$LOCATION")" ]; then
                    echo "[WARNING] different file name in LOCATION comment ("$(basename "$FILE")" != "$(basename "$LOCATION")")"
                fi

                do_install "$(dirname "$LOCATION")" "$OWNER" "$PERMS" "$FILE"
            fi
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

do_dir ./backup root:root 755
do_dir ./monitoring root:root 755
do_dir ./package root:root 755
do_dir ./webserver root:root 755

# special cases
#do_install /usr/local/sbin root:root 755 monitoring/package-versions.sh

