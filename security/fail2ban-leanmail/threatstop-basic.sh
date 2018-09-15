#!/bin/bash
#
# Update ThreatSTOP Basic blocklist.
#

# Usage
# Add device IP at https://www.threatstop.com/

PUBLIC_LIST="/home/web/website/html/ts/threatstop-basic.txt"
# Query ts-dns1.threatstop.com.
THREATSTOP_DNS="64.87.26.147"

host -W 5 -t A "basic.threatstop.local" "$THREATSTOP_DNS" \
    | sed -n -e 's|^basic\.threatstop\.local\. has IPv4 address \([0-9.]\+\)$|\1|p' \
    > "$PUBLIC_LIST"

exit 0
