#!/bin/bash
#
# Create database and database user from wp-config.php
# Needs user, password and default-character-set in ~/.my.cnf [mysql] section.
#
# VERSION       :0.2.0
# DATE          :2016-01-07
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/wp-createdb.sh

WP_CONFIG="./wp-config.php"

Get_wpconfig_var() {
    local VAR="$1"

    # UNIX or Windows lineends
    if ! [ -r "$WP_CONFIG" ] || ! grep -q "^define.*${VAR}.*;.\?$" "$WP_CONFIG"; then
        read -r -p "${VAR}? " DB_VALUE
        if [ -z "$DB_VALUE" ]; then
            echo "Cannot set variable (${VAR})" 1>&2
            exit 4
        fi
        echo "$DB_VALUE"
        return
    fi
    grep "^define.*${VAR}.*;.\?$" "$WP_CONFIG" | cut -d"'" -f4
}

which mysql &> /dev/null || exit 1
# Check credentials
echo "exit" | mysql || exit 3

DBNAME="$(Get_wpconfig_var "DB_NAME")"
DBUSER="$(Get_wpconfig_var "DB_USER")"
DBPASS="$(Get_wpconfig_var "DB_PASSWORD")"
DBHOST="$(Get_wpconfig_var "DB_HOST")"
DBCHARSET="$(Get_wpconfig_var "DB_CHARSET")"
# "DB_COLLATE"

# Exit on non-UTF8 charset
[[ "$DBCHARSET" =~ utf8 ]] || exit 99

echo "Database: ${DBNAME}"
echo "User:     ${DBUSER}"
echo "Password: ${DBPASS}"
echo "Host:     ${DBHOST}"
echo "Charset:  ${DBCHARSET}"
echo
read -r -p "CREATE DATABASE? " -n 1

[ "$DBHOST" == "localhost" ] || echo "Connecting to ${DBHOST} ..."

mysql --default-character-set=utf8 --host="$DBHOST" <<EOF || echo "Couldn't setup up database (MySQL error: $?)" >&2
CREATE DATABASE IF NOT EXISTS \`${DBNAME}\`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_general_ci';
-- "GRANT ALL PRIVILEGES" creates the user
-- CREATE USER '${DBUSER}'@'${DBHOST}' IDENTIFIED BY '${DBPASS}';
GRANT ALL PRIVILEGES ON \`${DBNAME}\`.* TO '${DBUSER}'@'${DBHOST}'
    IDENTIFIED BY '${DBPASS}';
FLUSH PRIVILEGES;
EOF

echo "wp core config --dbname=\"$DBNAME\" --dbuser=\"$DBUSER\" --dbpass=\"$DBPASS\" \\"
echo "    --dbhost=\"$DBHOST\" --dbprefix=\"prod\" --dbcharset=\"$DBCHARSET\" --extra-php <<EOF"
