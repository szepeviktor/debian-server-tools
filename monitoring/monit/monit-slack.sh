#!/bin/bash
#
# Send Monit alert to Slack.
#
# VERSION       :0.1.2
# DATE          :2017-09-26
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :https://mmonit.com/monit/documentation/monit.html#ENVIRONMENT
# DEPENDS       :pip3 install slack-webhook-cli
# LOCATION      :/usr/local/sbin/monit-slack.sh

# Usage
#
# Edit webhook, then modify Monit service configuration
#
#     #if status != 0 then alert
#     if status != 0 then exec "/usr/local/sbin/monit-slack.sh 'SLACK_WEBHOOK_URL'" uid "nobody" gid "nogroup"

WEB_HOOK="$1"

Message() {
    echo "Date:        $MONIT_DATE"
    echo "Service:     $MONIT_SERVICE"
    echo "Event:       $MONIT_EVENT"

    if [ -n "$MONIT_PROGRAM_STATUS" ]; then
        echo "Status:      $MONIT_PROGRAM_STATUS"
    fi

    echo "Description: $MONIT_DESCRIPTION"
}

set -e

test -n "$WEB_HOOK"
test -n "$MONIT_HOST"

Message | slack -w "$WEB_HOOK" -u "$MONIT_HOST" -
