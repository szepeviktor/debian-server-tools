#!/bin/bash
#
# Add the repositories that you install software from.
#
# VERSION       :0.1.1
# DATE          :2016-01-19
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/apt-add-repo.sh

# Usage
#
#     apt-add-repo.sh nodejs percona


Possible_locations() {
    cat <<-EOF
		${D}/package/apt-sources/${REPO}.list
		${D}/package/apt-sources/${REPO}
		./package/apt-sources/${REPO}.list
		./package/apt-sources/${REPO}
		./${REPO}.list
		./${REPO}
		/usr/local/src/debian-server-tools/package/apt-sources/${REPO}.list
		/usr/local/src/debian-server-tools/package/apt-sources/${REPO}
		/root/src/debian-server-tools/package/apt-sources/${REPO}.list
		/root/src/debian-server-tools/package/apt-sources/${REPO}
		EOF
}

for REPO in "$@"; do
    LIST=""
    while read -r LOCATION ; do
        if [ -r "$LOCATION" ]; then
            LIST="$LOCATION"
            break
        fi
    done < <(Possible_locations)

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
