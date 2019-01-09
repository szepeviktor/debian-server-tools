#!/bin/bash
#
# Display GitLab CI Variables
#

ENV="${1:-PROD}"

# cd "/home/$(stat -c %U .)/website/"
test "$(basename "$(pwd)")" == website || exit 10
# u ssh-keygen -t ecdsa
test -r ../.ssh/id_ecdsa || exit 11

CD_SSH_PORT="$(/usr/sbin/sshd -T | sed -n -e 's/^port \([0-9]\+\)$/\1/p')"
echo "${ENV}_CD_SSH_HOST $(hostname)"
echo "${ENV}_CD_SSH_PORT ${CD_SSH_PORT}"
echo "${ENV}_CD_SSH_USER $(stat -c %U .)"

echo "${ENV}_CD_SSH_SCRIPT $(pwd)/gitlab-deploy-receiver.sh"

echo "${ENV}_CD_SSH_KNOWN_HOSTS_B64 $(ssh-keyscan -p ${CD_SSH_PORT} $(hostname) | base64 -w 0)"
echo "${ENV}_CD_SSH_KEY_B64 $(cat ../.ssh/id_ecdsa | base64 -w 0)"
