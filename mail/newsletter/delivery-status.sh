#!/bin/bash
#
# List "message/delivery-status" message parts from a maildir.
#
# Usage
#     cd maildir/
#     ../delivery-status.sh | cut -d" " -f4

find . -type f | while read -r FILE; do
    DSN="$(sed -e '/^Content-Type: message\/delivery-status/,/^--/!d' "$FILE")"

    if [ -n "$DSN" ] && grep -q '^Final-Recipient:\|^Original-Recipient:' <<<"$DSN"; then
        echo -n "message/delivery-status: "
        { grep '^Original-Recipient:' <<<"$DSN" || grep '^Final-Recipient:' <<<"$DSN"; } \
            | sed -e 's/rfc822;\([^ ]\)/rfc822; \1/'
    else
        echo "--- UNKNOWN: ${FILE} - From: $(grep -m 1 '^From:' "$FILE")" 1>&2
    fi
done
