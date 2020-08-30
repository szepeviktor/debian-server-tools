#!/bin/bash
#
# Help setup GitLab CI.
#

ENV="${1:-PROD}"

Pause()
{
    read -r -s -p "Press any key to continue ..."
    echo
}

CURRENT_DIR="$(pwd)"
test "$(basename "$CURRENT_DIR")" == website || exit 10
# u ssh-keygen -t ed25519
test -r ../.ssh/id_ecdsa || test -r ../.ssh/id_ed25519 || exit 11

# In form of group/project
read -r -p "GITLAB_PROJECT=" GITLAB_PROJECT

# CI Container
echo "Create api+read_repository token: https://gitlab.com/profile/personal_access_tokens"
echo "docker login registry.gitlab.com"
echo "docker push registry.gitlab.com/${GITLAB_PROJECT}:0.0"
echo "docker logout registry.gitlab.com"
echo "https://gitlab.com/${GITLAB_PROJECT}/container_registry"
Pause

# CI Configuration
echo "Add container to .gitlab-ci.yml"
echo "image: registry.gitlab.com/${GITLAB_PROJECT}:0.0"
Pause

# Display GitLab CI Variables.
# cd /home/$(stat -c %U .)/website/
CD_SSH_PORT="$(/usr/sbin/sshd -T -C user=root -C host=localhost -C addr=localhost | sed -n -e 's/^port \([0-9]\+\)$/\1/p')"
echo "${ENV}_CD_SSH_HOST $(hostname)"
echo "${ENV}_CD_SSH_PORT ${CD_SSH_PORT}"
echo "${ENV}_CD_SSH_USER $(stat -c %U .)"

echo "${ENV}_CD_SSH_SCRIPT ${CURRENT_DIR}/gitlab-deploy-receiver.sh"

echo "${ENV}_CD_SSH_KNOWN_HOSTS_B64 $(ssh-keyscan -p ${CD_SSH_PORT} $(hostname) | base64 -w 0)"
if [ -r ../.ssh/id_ecdsa ]; then
    echo "${ENV}_CD_SSH_KEY_B64 $(cat ../.ssh/id_ecdsa | base64 -w 0)"
elif [ -r ../.ssh/id_ed25519 ]; then
    echo "${ENV}_CD_SSH_KEY_B64 $(cat ../.ssh/id_ed25519 | base64 -w 0)"
else
    exit 12
fi

echo "OK."
