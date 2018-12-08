#!/bin/bash
#
# Run WordPress cron from CLI.
#
# VERSION       :0.11.1
# DATE          :2018-08-17
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS5      :apt-get install php5-cli
# DEPENDS       :apt-get install php7.2-cli
# LOCATION      :/usr/local/bin/wp-cron-cli.sh

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
#     01,31 *  * * *  webuser	/usr/local/bin/wp-cron-cli.sh /home/webuser/website/code

WPCRON_LOCATION="$1"

Die()
{
    local RET="$1"

    shift
    echo -e "[wp-cron-cli] ${*}" 1>&2
    exit "$RET"
}

# shellcheck disable=SC2120
Get_meta()
{
    # Defaults to self
    local FILE="${1:-$0}"
    # Defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE

    VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\\s*:" | cut -d ":" -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

# Look for usual document root: /home/user/website/code
if [ -z "$WPCRON_LOCATION" ] \
    && [ -f "${HOME}/website/code/wp-cron.php" ]; then
    WPCRON_DIR="${HOME}/website/code"
# Directly specified
elif [ "$(basename "$WPCRON_LOCATION")" == "wp-cron.php" ] \
    && [ -f "$WPCRON_LOCATION" ]; then
    WPCRON_DIR="$(dirname "$WPCRON_LOCATION")"
# "website" directory
elif [ -f "${WPCRON_LOCATION}/html/wp-cron.php" ]; then
    WPCRON_DIR="${WPCRON_LOCATION}/html"
# WordPress root directory
elif [ -f "${WPCRON_LOCATION}/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
else
    Die 1 "Wp-cron not found (${WPCRON_LOCATION})"
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
# shellcheck disable=SC2119
WPCRON_VERSION="$(Get_meta)"
export HTTP_USER_AGENT="Wp-cron/${WPCRON_VERSION} (php-cli; Linux)"

cd "$WPCRON_DIR" || Die 2 "Cannot change to directory (${WPCRON_DIR})"
test -r wp-cron.php || Die 3 "File not found (${WPCRON_DIR}/wp-cron.php)"

# Alternative:  wp cron event run --due-now
nice /usr/bin/php7.2 -d mail.add_x_header=Off -d user_ini.filename="" wp-cron.php \
    || Die 4 "PHP exit status ${?} in ${WPCRON_DIR}/wp-cron.php"

exit 0
