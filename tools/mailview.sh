#!/bin/bash
#
# Read a single email file.
#

set -e

MESSAGE="$1"

test -r "$MESSAGE"

TMP_MSG="$(mktemp)"

# Convert to mailbox format
{
    echo "From sender@example.com $(date "+%a %b %e %T %Y")"
    cat "$MESSAGE"
} >"$TMP_MSG"

# Read email
s-nail -S "pipe-text/html=w3m -T text/html" -R -f "$TMP_MSG"

# Delete mailbox
rm "$TMP_MSG"
