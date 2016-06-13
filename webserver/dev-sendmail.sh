#!/bin/dash
#
# Dump email to a file.
#
# LOCATION      :/usr/local/sbin/dev-sendmail.sh

# Must be world writable or use SUID
DUMP_PATH="/tmp"

{
    [ -z "$*" ] || echo "X-Sendmail-Args: $*"
    # Decode: cat X-Sendmail-PP | base64 -d -i | LC_ALL=C tr '\0-\10\13\14\16-\37' '[ *]'
    echo "X-Sendmail-PP: $(base64 -w 60 /proc/$PPID/cmdline | sed -e '2,$s/^/  /')"
    cat
} > "${DUMP_PATH}/$(/bin/date "+%F_%H.%M.%S.%N_%z").eml"
