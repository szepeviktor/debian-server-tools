#!/bin/bash
#
# Find broken maildir symlinks.
#
# LOCATION      :/usr/local/sbin/broken-maildir.sh
# CRON-DAILY    :/usr/local/sbin/broken-maildir.sh

MAIL_BASE="/var/mail"

BROKEN="$(find "$MAIL_BASE" -type l -xtype l)"
if [ -n "$BROKEN" ]; then
    echo "$BROKEN"
    echo "Found broken maildir" 1>&2
fi

exit 0
