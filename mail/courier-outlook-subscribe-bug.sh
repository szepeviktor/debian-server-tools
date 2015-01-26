#!/bin/bash
#
# Find 'courierimapsubscribed' files with an empty line.
# Could be a weekly cron job.
# Courier IMAP error message: "Error reading ACLs for : Invalid argument"
#
# SOURCE  :https://www.howtoforge.de/forum/threads/courier-imapd-fehlermeldung-error-reading-acls-for-invalid-argument.3768/#post-27735

MAIL_BASE="/var/mail"

for CISSD in $(find "$MAIL_BASE" -type f -name "courierimapsubscribed" -exec grep -l '^$' \{\} \;); do
    echo "Empty subscription: ${CISSD}" >&2
    # correct it
    sed -i '/^$/d' "$CISSD"
done
