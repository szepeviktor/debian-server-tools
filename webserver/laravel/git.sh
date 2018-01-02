#!/bin/bash
#
# Run as a cron job: git.sh status --porcelain

# Exclude a period
[ 1500000000 -gt $(date +%s) ] && exit 0

git --git-dir=/home/user/Repo/.git --work-tree=/home/user/website/html "${@:-status}"

/usr/local/bin/composer --working-dir=/home/user/website/html install --quiet --no-dev --dry-run
