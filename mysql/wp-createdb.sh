#!/bin/bash
#
# Create database and database user from wp-config.php
#
# VERSION       :0.4.1
# DATE          :2018-09-05
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-createdb.sh

# Needs MySQL access.

WP_CONFIG="./wp-config.php"

Get_wpconfig_var() {
    local VAR="$1"
    local DEFAULT="$2"

    # Support UNIX or Windows line endings
    if [ ! -r "$WP_CONFIG" ] || ! grep -q "^define.*\\b${VAR}\\b.*;.\\?\$" "$WP_CONFIG"; then
        if [ -z "$DEFAULT" ]; then
            read -r -e -p "${VAR}? " DB_VALUE
        else
            read -r -e -i "$DEFAULT" -p "${VAR}? " DB_VALUE
        fi
        if [ -z "$DB_VALUE" ]; then
            echo "Cannot set variable (${VAR})" 1>&2
            exit 4
        fi
        echo "$DB_VALUE"
        return
    fi
    grep "^define.*\\b${VAR}\\b.*;.\\?\$" "$WP_CONFIG" | cut -d "'" -f 4
}

set -e

hash mysql 2> /dev/null

# Check database access
mysql --execute="EXIT"

DEFAULT_PASS="$(apg -n 1 -m 18)"

DBNAME="$(Get_wpconfig_var "DB_NAME")"
DBUSER="$(Get_wpconfig_var "DB_USER")"
DBPASS="$(Get_wpconfig_var "DB_PASSWORD" "$DEFAULT_PASS")"
DBHOST="$(Get_wpconfig_var "DB_HOST" "localhost")"
DBCHARSET="$(Get_wpconfig_var "DB_CHARSET" "utf8")"
# "DB_COLLATE"

# Exit on non-UTF8 charset
if [[ ! "$DBCHARSET" =~ [Uu][Tt][Ff]8 ]]; then
    echo "DB_CHARSET is not 'UTF8'" 1>&2
    exit 10
fi

# Display results
echo "Database: ${DBNAME}"
echo "User:     ${DBUSER}"
echo "Password: ${DBPASS}"
echo "Host:     ${DBHOST}"
echo "Charset:  ${DBCHARSET}"
echo
read -r -p "CREATE DATABASE? " -n 1

if [ "$DBHOST" != localhost ]; then
    echo "Connecting to ${DBHOST} ..."
fi

mysql --default-character-set=utf8 --host="$DBHOST" <<EOF || echo "Couldn't setup up database (MySQL error: ${?})" 1>&2
CREATE DATABASE IF NOT EXISTS \`${DBNAME}\`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';
-- "GRANT ALL PRIVILEGES" creates the user
-- CREATE USER '${DBUSER}'@'${DBHOST}' IDENTIFIED WITH mysql_native_password BY '${DBPASS}';
GRANT ALL PRIVILEGES ON \`${DBNAME}\`.*
    TO '${DBUSER}'@'${DBHOST}'
    IDENTIFIED BY '${DBPASS}';
FLUSH PRIVILEGES;
EOF

printf 'wp core config --dbname="%s" --dbuser="%s" --dbpass="%s" --dbhost="%s" --dbprefix="prod_" --dbcharset="%s"  # --extra-php <<"EOF"\n' \
    "$DBNAME" "$DBUSER" "$DBPASS" "$DBHOST" "$DBCHARSET"
