#!/bin/bash

cd /home/user/website/html/storage/logs/

grep -A 1 '^\[[0-9]\{4\}' "laravel-$(date "+%Y-%m-%d").log"
