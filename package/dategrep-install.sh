#!/bin/bash
#
# Install or update to the latest dategrep "small" release
#
# VERSION       :0.1.0
# DATE          :2016-02-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# UPSTREAM      :https://github.com/mdom/dategrep

set +e

DATEGREP="/usr/local/bin/dategrep"
DATEGREP_RELEASES="https://api.github.com/repos/mdom/dategrep/releases"
DATEGREP_URL_TPL="https://github.com/mdom/dategrep/releases/download/%s/dategrep-standalone-small"

apt-get install -y libdate-manip-perl

LATEST="$(wget -q -O- "$DATEGREP_RELEASES" | sed -ne '0,/^.*"tag_name": "\([0-9.]\+\)".*$/{s//\1/p}')"
printf -v LATEST_URL "$DATEGREP_URL_TPL" "$LATEST"

wget -nv -O "$DATEGREP" "$LATEST_URL"
chmod +x "$DATEGREP"

ls -l "$DATEGREP"
