#!/bin/bash
#
# Add the repositories that you install software from.
#
# VERSION       :0.1.0
# DATE          :2016-01-13
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install package
# LOCATION      :/usr/local/sbin/apt-add-repo.sh

# Usage
#
#     apt-add-repo.sh nodejs percona


for REPO in "$@"; do
    LIST=""
    if [ -r "${D}/package/apt-sources/${REPO}.list" ]; then
        LIST="${D}/package/apt-sources/${REPO}.list"
    elif [ -r "${D}/package/apt-sources/${REPO}" ]; then
        LIST="${D}/package/apt-sources/${REPO}"
    elif [ -r "${REPO}" ]; then
        LIST="${REPO}"
    elif [ -r "${REPO}.list" ]; then
        LIST="${REPO}.list"
    fi

    # Not a .list file
    [ "$LIST" == "${LIST%.list}" ] && exit 1

    # Does not exist
    [ -z "$LIST" ] && exit 2

    # Add the repo
    cp -v --backup "$LIST" /etc/apt/sources.list.d/

    # Import key
    grep -h -A 5 "^deb " "$LIST" \
        | grep "^#K: " | cut -d " " -f 2- \
        | xargs -r -L 1
done
