#!/bin/bash
#
# Check working tree and files of composer packages.
#
# CRON.D        :59 *	* * *	User	/home/User/website/git.sh status --porcelain

# Exclude a period
test 1500000000 -gt "$(date +%s)" && exit 0

git --git-dir=/home/User/Repo/.git --work-tree=/home/User/website/code "${@:-status}"

/usr/local/bin/composer --working-dir=/home/User/website/code install \
    --prefer-dist --no-dev --classmap-authoritative --no-suggest --no-scripts --dry-run 2>&1 \
    | grep -q -F -x 'Nothing to install or update'
