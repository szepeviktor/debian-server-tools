#!/bin/bash
#
# Start a Pull Request.
#

FORK_URL="$1"
UPSTREAM_URL="$2"
PR_BRANCH="$3"

set -e -x

test -n "$FORK_URL"
test -n "$UPSTREAM_URL"
test -n "$PR_BRANCH"

# Clone the fork and the upsream repositories
git clone "$FORK_URL"
cd "$(basename -s ".git" "$FORK_URL")/"
git remote add upstream "$UPSTREAM_URL"
git fetch upstream

# Check branch name
git branch
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" != master ]; then
    echo "Default branch is NOT master"
fi

# Merge upstream
git merge "upstream/${BRANCH}"
git status

# Create new branch for the PR
git branch "$PR_BRANCH"
git checkout "$PR_BRANCH"

# Instruction
echo "cd $(basename -s ".git" "$FORK_URL")/"
