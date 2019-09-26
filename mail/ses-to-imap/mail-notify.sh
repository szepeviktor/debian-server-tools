#!/bin/bash
#
# Check for new messages and notify on Slack.
#
# VERSION       :0.1.1
# DATE          :2018-02-02
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :pip3 install slack-webhook-cli
# LOCATION      :/usr/local/bin/mail-notify.sh

# Cron example
# */10 *  * * *  virtual	/usr/local/bin/mail-notify.sh "/var/mail/Maildir/new" "https://hooks.slack.com/services/ABC123"

MAIL_FOLDER="$1"
WEB_HOOK="$2"

ICON_URL="https://assets.change.org/photos/7/az/tr/URAzTrefPrgDHRC-128x128-noPad.jpg"

if [ -n "$(find "$MAIL_FOLDER" -type f)" ]; then
    /usr/local/bin/slack -w "$WEB_HOOK" -u "@$(hostname -d)" -i "$ICON_URL" "You've got mail"
fi

exit 0
