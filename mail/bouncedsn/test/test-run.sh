#!/bin/bash

set -e

PHP_BIN="/usr/bin/php7.2"
TEST_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"

# Switch to this directory
cd "$(dirname "$TEST_SCRIPT")"

# SparkPost
cp .env.sparkpost ../.env
"$PHP_BIN" ../bounce_handler.php <sparkpost-post.json
echo
rm ../.env
echo "SparkPost: OK."

# Amazon SES
cp .env.amazonses ../.env
"$PHP_BIN" ../bounce_handler.php <amazonses-post.json
echo
rm ../.env
echo "Amazon SES: OK."
