#!/bin/bash
#
# Uninstall a tool from debian-server-tools.
#
# VERSION       :0.1.1
# DATE          :2018-01-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+

Die() {
    local RET="$1"

    shift

    echo -e "$*" 1>&2
    exit "$RET"
}

Get_meta() {
    # defaults to self
    local FILE="${1:-$0}"
    # defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE

    VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\\s*:" | cut -d ":" -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

Do_uninstall() {
    local FILE="$1"
    local SYMLINK
    local SCRIPT

    SCRIPT="$(Get_meta "$FILE" LOCATION)"
    if [ -z "$SCRIPT" ] || [ "$SCRIPT" == "(unknown)" ]; then
        Die 2 "Invalid location (${SCRIPT})"
    fi

    # Check for existence
    if [ -f "$SCRIPT" ]; then
        echo "Uninstalling ${SCRIPT}"
    else
        Die 3 "Script does not exist (${SCRIPT})"
    fi

    # Uninstall
    rm -v "$SCRIPT" || Die 11 "Uninstallation failure (${SCRIPT})"

    # Create symlink
    head -n 30 "$FILE" | grep '^# SYMLINK\s*:' | cut -d ":" -f 2- \
        | while read -r SYMLINK; do
            echo -n "Removing symlink "
            rm -v "$SYMLINK" || Die 12 "Symbolic link creation failure (${SYMLINK})"
        done

    # Cron jobs
    if head -n 30 "$FILE" | grep -q -i '^# CRON'; then
        "$(dirname "$0")/uninstall-cron.sh" "$FILE" || Die 13 "Cron uninstallation failure (${SCRIPT})"
    fi
}

UNINSTALL_PATH="$1"

# Check user
if [[ $EUID -ne 0 ]]; then
    Die 1 "Only root is allowed to uninstall"
fi

# Display version
if [ "$UNINSTALL_PATH" == "--version" ]; then
    Get_meta
    exit 0
fi

if [ -f "$UNINSTALL_PATH" ]; then
    Do_uninstall "$UNINSTALL_PATH"
else
    Die 2 "Specified file does not exist (${UNINSTALL_PATH})"
fi
