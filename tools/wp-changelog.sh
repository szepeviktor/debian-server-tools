#!/bin/bash
#
# Display WordPress plugin changelog.
#
# VERSION       :1.1.0
# DATE          :2016-09-04
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install php-cli w3m
# SOURCE        :http://wp-cli.org/docs/shell-tips/
# LOCATION      :/usr/local/bin/wp-changelog.sh

# Press Shift + Q to quit from w3m

PLUGIN="$1"

set -e

test -n "$PLUGIN"

# shellcheck disable=SC2016
wget -q -O- "http://api.wordpress.org/plugins/info/1.0/${PLUGIN}" \
    | php -r '$s=unserialize(stream_get_contents(STDIN));echo $s->sections["changelog"];' \
    | w3m -T "text/html"
