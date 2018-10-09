#!/bin/bash

# SparkPost
cp -v .env.sparkpost ../.env
cd ../
composer install
/usr/bin/php7.2 bounce_handler.php <test/sparkpost-post.json
