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


Die() {
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
GetVersion() {
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
GetLocation() {
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
DoInstall() {
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
        mkdir -p "$LOCATION" || Die 10 "cannot create dir (${LOCATION})"
    fi

    for TOOL in "$@"; do
        TARGET="${LOCATION}/$(basename "$TOOL")"
        echo "install: ${TARGET}"

        # check the file in place
        if diff -q "$TOOL" "$TARGET" &> /dev/null; then
            echo "${TOOL}: already up-to-date"
            continue
        fi

        # check for existence
        if [ -f "$TARGET" ]; then
            echo -n "replacing $(GetVersion "$TARGET") with $(GetVersion "$TOOL") "
        fi

        # copy and set owner and permissions
        cp -v "$TOOL" "$TARGET" || Die 11 "copy failure (${TOOL})"
        chown --changes ${OWNER} "$TARGET" || Die 12 "cannot set owner (${TOOL})"
        chmod --changes ${PERMS} "$TARGET" || Die 13 "cannot set permissions (${TOOL})"
    done
}

#####################################################
# Process all files in a directory NOT recursively
# Arguments:
#   DIR
#   OWNER
#   PERMS
#####################################################
DoDir() {
    local DIR="$1"
    local OWNER="$2"
    local PERMS="$3"
    local FILE
    local LOCATION

    find "$DIR" -maxdepth 1 -type f \
        | while read FILE; do
            LOCATION="$(GetLocation "$FILE")"

            if ! [ -z "$LOCATION" ]; then
                # warn on different actual file name and file name in LOCATION
                if ! [ "$(basename "$FILE")" = "$(basename "$LOCATION")" ]; then
                    echo "[WARNING] different file name in LOCATION comment ("$(basename "$FILE")" != "$(basename "$LOCATION")")"
                fi

                DoInstall "$(dirname "$LOCATION")" "$OWNER" "$PERMS" "$FILE"
            fi
        done
}


#########################################################

[ "$(id --user)" = 0 ] || Die 1 "only root is allowed to install"

# version
if [ "$1" = "--version" ]; then
    GetVersion "$0"
    exit 0
fi

echo "debian-server-tools installer"

DoDir ./backup root:staff 755
DoDir ./monitoring root:staff 755
DoDir ./package root:staff 755
DoDir ./webserver root:staff 755
DoDir ./webserver/nginx-incron root:staff 755

# special cases
DoInstall /root/hdd-bench root:root 700 ./monitoring/hdd-seeker/hdd-bench.sh
DoInstall /root/hdd-bench root:root 644 ./monitoring/hdd-seeker/seeker_baryluk.c \
    ./monitoring/hdd-seeker/seekmark-0.9.1.c

