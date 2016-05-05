#!/bin/bash
#
# Run WordPress cron from CLI.
#
# VERSION       :0.7.1
# DATE          :2015-07-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-cron-cli.sh
# DEPENDS       :apt-get install php5-cli

# Disable wp-cron in your wp-config.php
#
#     define( 'DISABLE_WP_CRON', true );
#
# Reasons for WP-Cron to fail could be due to:
#  - DNS issue in the server.
#  - Plugins conflict
#  - Heavy load in the server which results in WP-Cron not executed fully
#  - WordPress bug
#  - Using of cache plugins that prevent the WP-Cron from loading
#  - And many other reasons
#
# Create cron job
#
#     01,31 *	* * *	webuser	/usr/local/bin/wp-cron-cli.sh /home/webuser/website/html

# @TODO  drop $WPCRON_PATH

WPCRON_LOCATION="$1"

Die() {
    local RET="$1"
    shift
    echo -e "[wp-cron-cli] $*" >&2
    exit "$RET"
}

Get_meta() {
    # defaults to self
    local FILE="${1:-$0}"
    # defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\s*:" | cut -d ':' -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

# Look for usual document root: /home/user/website/html
if [ -z "$WPCRON_LOCATION" ] \
    && [ -f "${HOME}/website/html/wp-cron.php" ]; then
    WPCRON_DIR="${HOME}/website"
    WPCRON_PATH="html/wp-cron.php"
# Directly specified
elif [ "$(basename "$WPCRON_LOCATION")" == "wp-cron.php" ] \
    && [ -f "$WPCRON_LOCATION" ]; then
    WPCRON_DIR="$(dirname "$WPCRON_LOCATION")"
    WPCRON_PATH="wp-cron.php"
# "website" directory
elif [ -f "${WPCRON_LOCATION}/html/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
    WPCRON_PATH="html/wp-cron.php"
# WordPress root directory
elif [ -f "${WPCRON_LOCATION}/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
    WPCRON_PATH="wp-cron.php"
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

pushd "$WPCRON_DIR" > /dev/null || Die 2 "Cannot change to directory (${WPCRON_DIR})"
[ -r "$WPCRON_PATH" ] || Die 3 "File not found (${$WPCRON_PATH})"

#     wp --quiet cron event list --fields=hook,next_run_relative --format=csv \
#         | sed -ne 's;^\(.\+\),now$;\1;p' | xargs -r wp --quiet cron event run
# Since 0.24.0
#     wp cron event run --due-now
if ! nice /usr/bin/php "$WPCRON_PATH"; then
    RET="$?"
    Die 4 "PHP exit status ${RET} in ${WPCRON_DIR}/${WPCRON_PATH}"
fi

popd > /dev/null

exit 0
