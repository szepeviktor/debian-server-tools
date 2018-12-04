#!/bin/bash
#
# Find courierimapsubscribed files with an empty line.
#
# SOURCE        :https://www.howtoforge.de/forum/threads/courier-imapd-fehlermeldung-error-reading-acls-for-invalid-argument.3768/#post-27735
# LOCATION      :/usr/local/bin/courier-outlook-subscribe-bug.sh
# CRON-WEEKLY   :/usr/local/bin/courier-outlook-subscribe-bug.sh

# Could be a weekly cron job.
# Courier IMAP error message: "Error reading ACLs for : Invalid argument"

MAIL_BASE="/var/mail"

find "$MAIL_BASE" -type f -name "courierimapsubscribed" -exec grep -l '^$' "{}" ";" \
    | while read -r IMAPSS; do
        echo "Empty subscription: ${IMAPSS}" 1>&2
        # Correction by deletion
        sed -e '/^$/d' -i "$IMAPSS"
    done
