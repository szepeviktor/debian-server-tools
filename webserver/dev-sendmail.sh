#!/bin/dash
#
# Dump email to a file.
#
# VERSION       :0.2.1
# LOCATION      :/usr/local/bin/dev-sendmail.sh

# Must be world writable or use SUID
DUMP_PATH="/tmp"

MESSAGE_FILE_TEMPLATE="$(date "+%s.N%N").P${$}.RXXXXX.$(hostname -f).eml"
MESSAGE_FILE="$(mktemp -p "$DUMP_PATH" "$MESSAGE_FILE_TEMPLATE")"
{
    test -z "$*" || echo "X-Sendmail-Args: $*"
    # To decode:  grep X-Sendmail-PP | cut -d: -f2- | base64 -di | LC_ALL=C tr '\0-\10\13\14\16-\37' '[ *]'
    echo "X-Sendmail-PP: $(sed -e 's/\x0.*$//' "/proc/${PPID}/cmdline" | base64 -w 56 | sed -e '2,$s/^/\t/')"
    cat
} >"$MESSAGE_FILE"
