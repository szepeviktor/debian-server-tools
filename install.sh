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
# Parses out a meta value from a script
# Arguments:
#   FILE
#   META
#####################################################
Get_meta() {
    # defaults to self
    local FILE="${1:-$0}"
    # defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\s*:" | cut -d':' -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

#####################################################
# Copies files in place, sets permissions and owner
# Arguments:
#   LOCATION
#   OWNER
#   PERMS
#   <file> <file> ...
#####################################################
Do_install() {
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
            echo -n "replacing $(Get_meta "$TARGET") with $(Get_meta "$TOOL") "
        fi

        # copy and set owner and permissions
        #TODO install -v --no-target-directory --preserve-timestamps --owner="${OWNER%:*}" --group="${OWNER#*:}" --mode "${PERMS}" \
        #    "$TOOL" "$TARGET" || Die 11 "install failure (${TOOL})"
        cp -v "$TOOL" "$TARGET" || Die 11 "copy failure (${TOOL})"
        chown --changes ${OWNER} "$TARGET" || Die 12 "cannot set owner (${TOOL})"
        chmod --changes ${PERMS} "$TARGET" || Die 13 "cannot set permissions (${TOOL})"

        if head -n 30 "$TOOL" | grep -qi "^# CRON-"; then
            ./install-cron.sh "$TOOL"
        fi
    done
}

#####################################################
# Process all files in a directory NOT recursively
# Arguments:
#   DIR
#   OWNER
#   PERMS
#####################################################
Do_dir() {
    local DIR="$1"
    local OWNER="$2"
    local PERMS="$3"
    local FILE
    local LOCATION

    find "$DIR" -maxdepth 1 -type f \
        | while read FILE; do
            LOCATION="$(Get_meta "$FILE" LOCATION)"

            if [ -z "$LOCATION" ] || [ "$LOCATION" == "(unknown)" ]; then
                continue
            fi

            # warn on different actual file name and LOCATION meta
            if [ "$(basename "$FILE")" != "$(basename "$LOCATION")" ]; then
                echo "[WARNING] different file name in LOCATION header ($(basename "$FILE") != $(basename "$LOCATION"))" >&2
            fi

            Do_install "$(dirname "$LOCATION")" "$OWNER" "$PERMS" "$FILE"
        done
}


#########################################################

if [ "$(id --user)" -ne 0 ]; then
    Die 1 "Only root is allowed to install"
fi

# version
if [ "$1" == "--version" ]; then
    Get_meta
    exit 0
fi

echo "debian-server-tools installer"

Do_dir ./backup root:staff 755
Do_dir ./image root:staff 755
Do_dir ./mail root:staff 755
Do_dir ./monitoring root:staff 755
Do_dir ./mysql root:staff 755
Do_dir ./package root:staff 755
Do_dir ./security root:staff 755
Do_dir ./tools root:staff 755
Do_dir ./webserver root:staff 755
Do_dir ./webserver/nginx-incron root:staff 755

# special cases
Do_install /root/hdd-bench root:root 700 ./monitoring/hdd-seeker/hdd-bench.sh
Do_install /root/hdd-bench root:root 644 \
    ./monitoring/hdd-seeker/seeker_baryluk.c \
    ./monitoring/hdd-seeker/seekmark-0.9.1.c
