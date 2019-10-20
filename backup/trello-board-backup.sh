#!/bin/bash
#
# Download a complete board from Trello API.
#
# VERSION       :0.1.0
# DATE          :2019-10-17
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# REFS          :https://developers.trello.com/reference#boardsboardid-1
# LOCATION      :/usr/local/bin/trello-board-backup.sh

# Usage
# Create a cron job: cd /media/backup && trello-board-backup.sh "BOARD-ID" "API-KEY" "API-TOKEN"

BOARDS_ALL_QUERY="actions=all&actions_limit=1000&card_attachment_fields=all&cards=all&lists=all&members=all&member_fields=all&card_attachment_fields=all&checklists=all&fields=all"

set -e

BOARD_ID="$1"
API_KEY="$2"
API_TOKEN="$3"

test -n "$BOARD_ID"
test -n "$API_KEY"
test -n "$API_TOKEN"

printf -v API_URL 'https://api.trello.com/1/boards/%s?%s&key=%s&token=%s' \
    "$BOARD_ID" "$BOARDS_ALL_QUERY" "$API_KEY" "$API_TOKEN"

wget -q -O "./${BOARD_ID}.json" "$API_URL"
