#!/usr/bin/env python3
#
# Send message through Hangouts Chat webhook.
#
# VERSION        :0.1.0
# DATE           :2019-05-19
# AUTHOR         :Viktor Szépe <viktor@szepe.net>
# URL            :https://github.com/szepeviktor/debian-server-tools
# LICENSE        :The MIT License (MIT)
# PYTHON-VERSION :3.5+
# DOCS           :https://developers.google.com/hangouts/chat/quickstart/incoming-bot-python
# LOCATION       :/usr/local/bin/hangouts-notify.py

from httplib2 import Http
from json import dumps
import sys

CHAT_WEBHOOK = ''


def main(argv):
    message_headers = {'Content-Type': 'application/json; charset=UTF-8'}
    bot_message = {'text': argv[0]}

    http_obj = Http()

    (resp_headers, content) = http_obj.request(
        uri=CHAT_WEBHOOK,
        method='POST',
        headers=message_headers,
        body=dumps(bot_message)
    )

    if resp_headers.status == 200:
        return 0

    return 11


if __name__ == '__main__':
    exitcode = main(sys.argv[1:])
    sys.exit(exitcode)
