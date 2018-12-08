#!/bin/bash
#
# Change to a certain WordPress installation's directory.
#
# VERSION       :0.1.0
# DATE          :2017-08-10
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install whiptail
# DEPENDS       :wp-cli/find-command
# LOCATION      :/usr/local/sbin/wp-choose.sh

WP_TOP_PATH="/home/"
MENU_TEXT="Choose an installation"
GAUGE_TEXT="Searching for WordPress"

set -e

# Detect find command
wp --allow-root cli cmd-dump | grep -q '{"name":"find",'

declare -a MENU
WPS="$(wp --allow-root find "$WP_TOP_PATH" --field=version_path)"
WP_TOTAL="$(wc -l <<<"$WPS")"
WP_COUNT="0"

while read -r WP; do
    WP_LOCAL="${WP%wp-includes/version.php}"

    NAME="$(cd "$WP_LOCAL"; sudo -u "$(stat . -c %U)" -- wp --no-debug --quiet option get blogname)"
    if [ -z "$NAME" ]; then
        NAME="(unknown)"
    fi
    MENU+=( "$WP_LOCAL" "$NAME" )

    echo "$((++WP_COUNT * 100 / WP_TOTAL))"
done <<<"$WPS" > >(whiptail --gauge "$GAUGE_TEXT" 7 74 0)

if ! WP_LOCAL="$(whiptail --title "WordPress" --menu "$MENU_TEXT"  $((${#MENU[*]} / 2 + 7)) 74 10 "${MENU[@]}" 3>&1 1>&2 2>&3)" \
    || [ ! -d "$WP_LOCAL" ]; then
    echo "Cannot find '${WP_LOCAL}'" 1>&2
    exit 10
fi

echo "cd ${WP_LOCAL}"
