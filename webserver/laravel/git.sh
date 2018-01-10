#!/bin/bash
#
# Check working tree and files of composer packages.
#

# Run as a cron job: git.sh status --porcelain

# Exclude a period
test 1500000000 -gt "$(date +%s)" && exit 0

git --git-dir=/home/user/Repo/.git --work-tree=/home/user/website/html "${@:-status}"

/usr/local/bin/composer --working-dir=/home/user/website/html install \
    --prefer-dist --no-dev --classmap-authoritative --no-suggest --no-scripts --dry-run 2>&1 \
    | grep -qFx "Nothing to install or update"
