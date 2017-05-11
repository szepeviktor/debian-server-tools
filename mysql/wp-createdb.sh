#!/bin/bash
#
# Create database and database user from wp-config.php
#
# VERSION       :0.3.2
# DATE          :2016-02-22
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-createdb.sh
#
# Needs user, password and default-character-set
# in ~/.my.cnf [mysql] section.

WP_CONFIG="./wp-config.php"

Get_wpconfig_var() {
    local VAR="$1"
    local DEFAULT="$2"

    # Support UNIX or Windows line endings
    if ! [ -r "$WP_CONFIG" ] || ! grep -q "^define.*${VAR}.*;.\?$" "$WP_CONFIG"; then
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
    grep "^define.*${VAR}.*;.\?$" "$WP_CONFIG" | cut -d"'" -f4
}

hash mysql 2> /dev/null || exit 1

# Check database access
mysql --execute="EXIT" || exit 3

DBNAME="$(Get_wpconfig_var "DB_NAME")"
DBUSER="$(Get_wpconfig_var "DB_USER")"
DEFAULT_PASS="$(apg -n 1 -m 18)"
DBPASS="$(Get_wpconfig_var "DB_PASSWORD" "$DEFAULT_PASS")"
DBHOST="$(Get_wpconfig_var "DB_HOST" "localhost")"
DBCHARSET="$(Get_wpconfig_var "DB_CHARSET" "utf8")"
# "DB_COLLATE"

# Exit on non-UTF8 charset
[[ "$DBCHARSET" =~ [Uu][Tt][Ff]8 ]] || exit 99

echo "Database: ${DBNAME}"
echo "User:     ${DBUSER}"
echo "Password: ${DBPASS}"
echo "Host:     ${DBHOST}"
echo "Charset:  ${DBCHARSET}"
echo
read -r -p "CREATE DATABASE? " -n 1

if [ "$DBHOST" != "localhost" ]; then
    echo "Connecting to ${DBHOST} ..." 1>&2
fi

mysql --default-character-set=utf8 --host="$DBHOST" <<EOF || echo "Couldn't setup up database (MySQL error: $?)" 1>&2
CREATE DATABASE IF NOT EXISTS \`${DBNAME}\`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';
-- "GRANT ALL PRIVILEGES" creates the user
-- CREATE USER '${DBUSER}'@'${DBHOST}' IDENTIFIED WITH mysql_native_password BY '${DBPASS}';
GRANT ALL PRIVILEGES ON \`${DBNAME}\`.*
    TO '${DBUSER}'@'${DBHOST}'
    IDENTIFIED WITH mysql_native_password BY '${DBPASS}';
FLUSH PRIVILEGES;
EOF

echo -n "wp core config --dbname=\"$DBNAME\" --dbuser=\"$DBUSER\" --dbpass=\"$DBPASS\""
echo " --dbhost=\"$DBHOST\" --dbprefix=\"prod_\" --dbcharset=\"$DBCHARSET\"  # --extra-php <<EOF"
