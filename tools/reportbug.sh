#!/bin/bash
#
# Report a bug to Debian BTS.
#
# VERSION       :0.1.1
# DATE          :2018-01-07
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install reportbug
# LOCATION      :/usr/local/bin/reportbug.sh

set -e

# Use at least 6.6.6 (jessie-backports)
if dpkg --compare-versions "$(dpkg-query --show --showformat='${Version}' reportbug)" le "6.6.5"; then
    echo "Please upgrade reportbug" 1>&2
    exit 100
fi

# Configure reportbug
if [ ! -f "${HOME}/.reportbugrc" ]; then
    cat > "${HOME}/.reportbugrc" <<EOF
reportbug_version "$(dpkg-query --show --showformat='${Version}' reportbug)"
mode advanced
ui text
realname "Viktor Szépe"
email "viktor@szepe.net"
EOF

fi

# Input package name, short description and message
read -r -e -p "Package name? " REPORTBUG_PACKAGE
read -r -e -p "Short description? " REPORTBUG_SUBJECT
# @FIXME NEWBIELINE always prepended with --body-file
#REPORTBUG_BODY="$(mktemp)"
#editor "$REPORTBUG_BODY"

#if [ -z "$REPORTBUG_PACKAGE" ] || [ -z "$REPORTBUG_SUBJECT" ] || [ ! -s "$REPORTBUG_BODY" ]; then
if [ -z "$REPORTBUG_PACKAGE" ] || [ -z "$REPORTBUG_SUBJECT" ]; then
    echo "Reporting cancelled."
    exit 0
fi

# Sends an email to submit@bugs.debian.org and to you
reportbug --mode=novice --no-query-bts --no-config-files --no-check-available \
    --no-debconf --no-check-installed --no-cc-menu --no-tags-menu --no-verify \
    --subject="$REPORTBUG_SUBJECT" "$REPORTBUG_PACKAGE"
#    --subject="$REPORTBUG_SUBJECT" --body-file="$REPORTBUG_BODY" "$REPORTBUG_PACKAGE"

echo "Exit status: ${?}"

# @FIXME
#rm "$REPORTBUG_BODY"
