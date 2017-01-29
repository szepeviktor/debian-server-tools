#!/bin/bash
#
# Show update instruction for installed tools.
#
# VERSION       :0.1.2
# DATE          :2015-07-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install colordiff

# Show also colorized diffs.
#
#     ./update.sh -d

PARAM="$1"

Get_meta() {
    # defaults to self
    local FILE="${1:-$0}"
    # defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE

    VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\s*:" | cut -d ":" -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

hash colordiff 2> /dev/null || unset PARAM

#Input_motd Get_meta input/update-motd.d - Get_meta /etc/update-motd.d/update-motd.d

D="$(dirname "$0")"
find -type f -size -100k -not -name README.md -not -path "*/.git*" -printf '%P\n' \
    | while read -r FILE; do
        SCRIPT="$(Get_meta "$FILE" LOCATION)"
        if [ -z "$SCRIPT" ] || [ "$SCRIPT" == "(unknown)" ] || ! [ -f "$SCRIPT" ]; then
            continue
        fi

        OLD_VERSION="$(Get_meta "$SCRIPT")"
        CURRENT_VERSION="$(Get_meta "$FILE")"
        if [ "$OLD_VERSION" == "$CURRENT_VERSION" ]; then
            continue
        fi

        echo "# Update ${FILE}: ${OLD_VERSION} -> ${CURRENT_VERSION}"
        echo "${D}/install.sh ${FILE}"
        if [ "$PARAM" == "-d" ]; then
            colordiff -wB "$SCRIPT" "$FILE"
        fi
    done
