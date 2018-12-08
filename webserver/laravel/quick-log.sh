#!/bin/bash
#
# Display first Laravel log lines.
#

cd /home/USER/website/code/storage/logs/ || exit 10

grep -A 1 '^\[[0-9]\{4\}' "laravel-$(date "+%Y-%m-%d").log"
