#!/bin/bash
#
# Install motd scripts.
#

set -e

# Dependencies
apt-get install -y figlet bc cowsay

if [ -d /etc/update-motd.d ]; then
    # Non-empty script directory
    [ -z "$(find /etc/update-motd.d/ -type f -prune)" ]
else
    mkdir -v /etc/update-motd.d
fi

# Backup original motd
mv -v /etc/motd /etc/motd~
# Make it a symlink
ln -svf /var/run/motd /etc/motd

# Trespass warning
echo "(hit Ctrl + D to change language)"
if read -r -e -p "Company name: " COMPANY; then
    echo -e "*\n*** This server is the property of ${COMPANY}. Unauthorized entry is prohibited. ***\n*\n" > /etc/motd.tail
else
    echo
    read -r -e -p "a/az + cégnév: " COMPANY
    echo -e "*\n*** Ez a szerver ${COMPANY} tulajdona. Idegeneknek a belépés tilos. ***\n*\n" > /etc/motd.tail
fi

# Hostname color
tput sgr0
for COLOR in 1 2 3 4 5 6 7; do
    tput setaf "$COLOR"
    echo -n "■${COLOR}■ "
    tput sgr0
done
echo
read -r -e -p "Host figlet color: " -i "7" HOSTCOLOR
echo "$HOSTCOLOR" > /etc/hostcolor

# Install scripts
cp -avf ./update-motd.d /etc/
cp -avf ./profile.d /etc/
