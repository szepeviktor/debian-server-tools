#!/bin/bash
#
# Install WordPress instantly using WP-CLI.
#

# Constants
INSTALLATION_DIRECTORY="wordpress"
CORE_VERSION="latest"
CORE_LANGUAGE="en_US"
DATABASE_USER="root"
DATABASE_PASSWORD=""
#DATABASE_PASSWORD="$(sed -n -e '0,/^password\s*=\s*\(\S\+\)\s*$/s//\1/p' ~/.my.cnf)"
DATABASE_NAME="wordpressdb"
DATABASE_TABLE_PREFIX="wp_"
# No trailing slash
PUBLIC_URL="http://localhost"
WEBSITE_TITLE="Instant WordPress"
ADMINISTRATOR_USER="instantadmin"
ADMINISTRATOR_PASSWORD="0123456"
ADMINISTRATOR_EMAIL="root@localhost"
PLUGIN_LIST="woocommerce wordpress-seo"

Error()
{
    echo "$*" 1>&2
    exit 10
}

Get_db_prefix()
{
    local PREFIX="$DATABASE_TABLE_PREFIX"
    local PREFIX_QUERY
    local TABLE

    while true; do
        printf -v PREFIX_QUERY 'SHOW TABLES LIKE "%s_options";' "$PREFIX"
        TABLE="$(mysql -N -u "$DATABASE_USER" -p"$DATABASE_PASSWORD" "$DATABASE_NAME" <<<"$PREFIX_QUERY")"
        test -z "$TABLE" && break

        # Table exists, try different prefix
        # shellcheck disable=SC2018
        PREFIX="$(tr -d -c 'a-z' </dev/urandom | head -c 2)"
    done
    echo "$PREFIX"
}

set -e

test -d "$INSTALLATION_DIRECTORY" && Error "Installation directory exists: ${INSTALLATION_DIRECTORY}"
wp core download \
    --path="$INSTALLATION_DIRECTORY" --version="$CORE_VERSION" --locale="$CORE_LANGUAGE"

cd "$INSTALLATION_DIRECTORY"

wp config create \
    --dbuser="$DATABASE_USER" --dbpass="$DATABASE_PASSWORD" \
    --dbname="$DATABASE_NAME" --dbprefix="$(Get_db_prefix)"
chmod 0600 ./wp-config.php

wp core install \
    --url="$PUBLIC_URL" --title="$WEBSITE_TITLE" \
    --admin_user="$ADMINISTRATOR_USER" --admin_password="$ADMINISTRATOR_PASSWORD" \
    --admin_email="$ADMINISTRATOR_EMAIL" --skip-email

# shellcheck disable=SC2086
wp plugin install \
    ${PLUGIN_LIST}

HOST_PORT="${PUBLIC_URL#*//}"
PORT="${HOST_PORT#*:}"
echo "wp server --host=${HOST_PORT%:*} --port=${PORT:-80}" \
    | tee "${INSTALLATION_DIRECTORY}/server.sh"
chmod +x "${INSTALLATION_DIRECTORY}/server.sh"

echo "OK."
