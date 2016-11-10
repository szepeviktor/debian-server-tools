#!/bin/bash
#
# Install or update to the latest dategrep "small" release.
#
# VERSION       :0.2.0
# DATE          :2016-11-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# UPSTREAM      :https://github.com/mdom/dategrep

DATEGREP="/usr/local/bin/dategrep"
DATEGREP_RELEASES="https://api.github.com/repos/mdom/dategrep/releases"
DATEGREP_URL_TPL="https://github.com/mdom/dategrep/releases/download/%s/dategrep-standalone-small"

set -e

apt-get install -y libdate-manip-perl

LATEST="$(wget -q -O- "$DATEGREP_RELEASES" | sed -n -e '0,/^.*"tag_name": "\(v[0-9.]\+\)".*$/{s//\1/p}')"
printf -v LATEST_URL "$DATEGREP_URL_TPL" "$LATEST"

wget -nv -O "$DATEGREP" "$LATEST_URL"
chmod +x "$DATEGREP"

"$DATEGREP" --version
