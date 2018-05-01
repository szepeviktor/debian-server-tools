#!/bin/bash
#
# Add the repositories that you install software from.
#
# VERSION       :0.3.0
# DATE          :2018-05-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/apt-add-repo.sh

# Usage
#
#     apt-add-repo.sh nodejs percona

set -e

Possible_locations()
{
    cat <<-EOF
		${D}/package/apt-sources/${REPO}.list
		${D}/package/apt-sources/${REPO}
		./package/apt-sources/${REPO}.list
		./package/apt-sources/${REPO}
		./${REPO}.list
		./${REPO}
		/usr/local/src/debian-server-tools/package/apt-sources/${REPO}.list
		/usr/local/src/debian-server-tools/package/apt-sources/${REPO}
		/root/src/debian-server-tools-master/package/apt-sources/${REPO}.list
		/root/src/debian-server-tools-master/package/apt-sources/${REPO}
		EOF
}

for REPO; do
    LIST=""
    while read -r LOCATION ; do
        if [ -r "$LOCATION" ]; then
            LIST="$LOCATION"
            break
        fi
    done < <(Possible_locations)

    # Not a .list file
    test "$LIST" != "${LIST%.list}"

    # Does not exist
    test -n "$LIST"

    # Add the repo
    cp -v --backup "$LIST" /etc/apt/sources.list.d/

    # Import key
    grep -h -A 5 "^deb " "$LIST" \
        | grep "^#K: " | cut -d " " -f 2- \
        | /bin/bash

    # Check fingerprint
    grep -h -A 5 "^deb " "$LIST" \
        | grep "^#F: " | cut -d " " -f 2- \
        | while read -r ID_FP; do
            KEY_ID="${ID_FP%:*}"
            FINGERPRINT="${ID_FP#*:}"
            CURRENT_FP="$(apt-key adv --with-colons --fingerprint "$KEY_ID" | sed -ne 's/^fpr:::::::::\([0-9A-F]\+\):$/\1/p')"
            if [ "$CURRENT_FP" != "$FINGERPRINT" ]; then
                rm -f "/etc/apt/sources.list.d/$(basename "$LIST")"
                apt-key del "$KEY_ID"
                echo "[CRITICAL] Fingerprint mismatch: (${CURRENT_FP} <> ${FINGERPRINT})" 1>&2
                exit 3
            fi
        done

    # APT preference
    grep -h -A 5 "^deb " "$LIST" \
        | grep "^#P: " | cut -d " " -f 2- \
        | /bin/bash
done

apt-get clean
apt-get update
