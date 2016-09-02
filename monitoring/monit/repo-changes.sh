#!/bin/bash
#
# Changes in watched monit repos
#
# DEPENDS       :apt-get install jq
# DEPENDS       :pip install html2text

FM_URL="https://storage.fladi.at/~FladischerMichael/monit/"
FM_MD5="b0ef615d2e2ecd15e6fb1cf91d3c8a6f"

Latest_commit() {
    local COMMIT_API_URL="$(wget -qO- "https://api.github.com/repos/$1/git/refs/heads/master" | jq -r .object.url)"
    local COMMIT_DATE="$(wget -qO- "$COMMIT_API_URL" | jq -r .author.date)"

    date -d "$COMMIT_DATE"
}

# 01. FladischerMichael/monit
CURRENT_MD5="$(wget -qO- "$FM_URL" | md5sum | cut -d " " -f 1)"
if [ "$CURRENT_MD5" != "$FM_MD5" ]; then
    echo "New FladischerMichael/monit service entry."
    wget -qO- "$FM_URL" | html2text --ignore-links | cut -d "|" -f 2-
fi

# 02.
Latest_commit "perusio/monit-miscellaneous"

# 03.
# Services from Debian: git clone https://anonscm.debian.org/git/collab-maint/monit.git
# Web: https://anonscm.debian.org/cgit/collab-maint/monit.git/tree/debian/conf-available

# 04.
# Monit examples: https://mmonit.com/wiki/Monit/ConfigurationExamples

# 05.
# https://extremeshok.com/5207/monit-configs-for-ubuntu-debian-centos-rhce-redhat/
