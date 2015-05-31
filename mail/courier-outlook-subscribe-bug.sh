#!/bin/bash
#
# Find 'courierimapsubscribed' files with an empty line.
# Could be a weekly cron job.
# Courier IMAP error message: "Error reading ACLs for : Invalid argument"
#
# SOURCE        :https://www.howtoforge.de/forum/threads/courier-imapd-fehlermeldung-error-reading-acls-for-invalid-argument.3768/#post-27735
# LOCATION      :/usr/local/bin/courier-outlook-subscribe-bug.sh
# CRON-WEEKLY   :/usr/local/bin/courier-outlook-subscribe-bug.sh

MAIL_BASE="/var/mail"

for IMAPSS in $(find "$MAIL_BASE" -type f -name "courierimapsubscribed" -exec grep -l '^$' \{\} \;); do
    echo "Empty subscription: ${IMAPSS}" >&2
    # Correct it by deletion
    sed -i '/^$/d' "$IMAPSS"
done
