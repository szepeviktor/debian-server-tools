#!/bin/bash
#
# Cleanup stale PHP-FPM sessions.
#
# UPSTREAM      :https://salsa.debian.org/php-team/php-defaults/blob/master/sessionclean
# DEPENDS       :apt-get install libfcgi-bin

Print_get_all_session()
{
    cat <<"EOF"
<?php

foreach (ini_get_all('session') as $key => $value) {
    printf('%s=%s' . "\n", $key, $value['local_value']);
}
EOF
}

Get_fpms()
{
    local PROC_NAMES=""

    # List all user:socket-file
    # shellcheck disable=SC2044
    for SOCKET in $(find /run/php/ -type s -printf '%u:%p\n'); do
        FPM_USER="${SOCKET%%:*}"
        FPM_SOCKET="${SOCKET#*:}"
        SCRIPT="$(getent passwd "$FPM_USER" | cut -d ":" -f 6)/website/get-session-data-${RANDOM}.php"
        Print_get_all_session >"$SCRIPT"

        # Connect to FPM socket
        SESSION_CONFIG_STRING="$(sudo -u "$FPM_USER" \
            SCRIPT_FILENAME="$SCRIPT" REQUEST_METHOD="GET" REQUEST_URI="/" QUERY_STRING="" \
            cgi-fcgi -bind -connect "$FPM_SOCKET")"
        rm "$SCRIPT"
        SAVE_HANDLER="$(sed -n -e 's/^session\.save_handler=\(.*\)$/\1/p' <<<"$SESSION_CONFIG_STRING")"
        SAVE_PATH="$(sed -n -e 's/^session\.save_path=\(.*\)$/\1/p' <<<"$SESSION_CONFIG_STRING")"
        GC_MAXLIFETIME="$(sed -n -e 's/^session\.gc_maxlifetime=\(.*\)$/\1/p' <<<"$SESSION_CONFIG_STRING")"

        # Only process sessions stored in files
        if [ "$SAVE_HANDLER" != files ] || [ ! -d "$SAVE_PATH" ]; then
            continue
        fi
        PROC_NAMES+=" $(lsof -F c "$FPM_SOCKET" | sed -n -e 's#^c\(php.\+\)$#\1#p')"
        # Print data
        printf '%s:%s\n' "$(realpath "$SAVE_PATH")" "$GC_MAXLIFETIME"
    done

    # Find all open session files and touch them
    # shellcheck disable=SC2086
    for PID in $(pidof ${PROC_NAMES}); do
        find "/proc/${PID}/fd" -ignore_readdir_race -lname "*/sess_*" \
            -exec touch --no-create "{}" ";" 2>/dev/null
    done
}

Gargabe_collect()
{
    while IFS=":" read -r SAVE_PATH GC_MAXLIFETIME; do
        # Find all files older then maxlifetime and delete them
        find -O3 "${SAVE_PATH}/" -ignore_readdir_race -depth -mindepth 1 -type f -name "sess_*" \
            -cmin "+$((GC_MAXLIFETIME / 60))" -delete
    done
}

set -e -o pipefail

Get_fpms | sort -u | Gargabe_collect

exit 0
