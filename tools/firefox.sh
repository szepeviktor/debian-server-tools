#!/bin/bash
#
# Simulate Mozilla Firefox with wget.
#
# VERSION       :1.0.1
# DATE          :2015-07-31
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/firefox.sh

# Firefox request example
#
#     GET /request/uri HTTP/1.1
#     Host: hostname:port
#     User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:55.0) Gecko/20100101 Firefox/55.0.2
#     Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
#     Accept-Language: en-US,en;q=0.5
#     Accept-Encoding: gzip, deflate
#     DNT: 1
#     Connection: keep-alive
#
# Wget has different request header order
#     User-Agent, Accept, Host, Connection, custom headers...
#
# Usage
#    ./firefox.sh -qO- http://example.com



UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:55.0) Gecko/20100101 Firefox/55.0.2"

/usr/bin/wget --user-agent="$UA" \
    --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    --header="Accept-Language: en-US,en;q=0.5" \
    --header="Accept-Encoding: gzip, deflate" \
    --header="DNT: 1" \
    --header="Connection: keep-alive" \
    "$@" | zgrep ""
