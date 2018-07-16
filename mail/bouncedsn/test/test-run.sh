#!/bin/bash

# SparkPost
cp -v .env.sparkpost ../.env
cd ../
composer install
php bounce_handler.php < test/sparkpost-post.json
