#!/bin/bash
#
# Run WordPress cron from CLI.
#
# VERSION       :0.4
# DATE          :2015-04-11
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# UPSTREAM      :https://github.com/szepeviktor/wplib/blob/master/bin/wp-cron.sh
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-cron.sh
# DEPENDS       :apt-get install php5-cli

# USAGE
# Copy this to your wp-config.php
#
# define( 'DISABLE_WP_CRON', true );

WPCRON_LOCATION="$1"

Die() {
    local RET="$1"
    shift
    echo -e "[wp-cron] $*" >&2
    exit "$RET"
}

Get_meta() {
    # defaults to self
    local FILE="${1:-$0}"
    # defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\s*:" | cut -d':' -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

# wp-cron.php directly specified
if [ -f "$WPCRON_LOCATION" ]; then
    WPCRON_PATH="$(basename "$WPCRON_LOCATION")"
    # Must be second
    WPCRON_DIR="$(dirname "$WPCRON_LOCATION")"
# WordPress root directory
elif [ -f "${WPCRON_LOCATION}/server/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
    WPCRON_PATH="server/wp-cron.php"
# WordPress root directory without /server
elif [ -f "${WPCRON_LOCATION}/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
    WPCRON_PATH="wp-cron.php"
# Look for usual document root (/home/user/public_html/server)
elif [ -z "$WPCRON_LOCATION" ] \
    && [ -f "/home/$(id -nu)/public_html/server/wp-cron.php" ]; then
    WPCRON_DIR="/home/$(id -nu)/public_html"
    WPCRON_PATH="server/wp-cron.php"
else
    Die 1 "wp-cron not found (${WPCRON_LOCATION})"
fi

# Set server and execution environment information
export REMOTE_ADDR="127.0.0.1"
#export SERVER_ADDR="127.0.0.1"
#export SERVER_SOFTWARE="Apache"
#export SERVER_SOFTWARE="nginx"
#export SERVER_NAME="<DOMAIN>"

# Request data
export REQUEST_METHOD="GET"
#export REQUEST_URI="/<SUBDIR>/wp-cron.php"
#export SERVER_PROTOCOL="HTTP/1.1"
#export HTTP_HOST="<DOMAIN>"
export HTTP_USER_AGENT="Wp-cron/$(Get_meta) (php-cli; Linux)"

pushd "$WPCRON_DIR" > /dev/null || Die 2 "Cannot change to directory ${WPCRON_DIR}"
[ -r "$WPCRON_PATH" ] || Die 3 "File not found ${$WPCRON_PATH}"
[ -x /usr/bin/php ] || Die 4 "PHP CLI not found"
if /usr/bin/php "$WPCRON_PATH"; then
    popd > /dev/null
else
    RET="$?"
    WPCRON_PWD="$(pwd)"
    popd > /dev/null
    Die 10 "PHP exit status ${RET} in ${WPCRON_PWD}/${WPCRON_PATH}"
fi
