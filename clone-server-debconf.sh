#!/bin/bash
#
# Clone a server by reinstalling packages and copying settings.
#

exit 0


# Save on the "donor"

apt-get install -y debconf-utils
mkdir /root/clone; cd /root/clone/
# Create etc-blacklist.txt from these
echo "/etc/modprobe.d/
/etc/network/interfaces
/etc/fstab
/etc/mdadm/mdadm.conf
/etc/udev/
/etc/hostname
/etc/hosts
/etc/resolv.conf
/etc/mailname
/etc/courier/me" | xargs -I%% find %% -type f > etc-blacklist.txt
ls /etc/ssh/ssh_host_*_key* >> etc-blacklist.txt

debconf-get-selections > debconf.selections
dpkg --get-selections > packages.selection
tar --exclude-from=etc-blacklist.txt \
    -vczf server.tar.gz debconf.selections packages.selection etc-blacklist.txt /etc/*
## Data dirs
# /home
# /opt
# /root
# /srv
# /usr/local
# /var
# /var/lib/mysql
# /var/cache
# /var/mail
# /var/spool
# /var/tmp
# @TODO Recreate dirs - owner, perms

## Special handling dirs
# /var/mail
# /var/lib/mysql
# /media/backup


# Restore on the "clone"

# Check hardware
clear; fdisk -l /dev/[svx]d?
cat /proc/mdstat
pvdisplay && lvs
ifconfig

# Clean package cache
apt-get clean
rm -vrf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Move data
cd
#ssh-keygen -t ecdsa -f /root/.ssh/id_ecdsa -N ""; cat /root/.ssh/id_ecdsa.pub
#scp -P ${PORT} -r ${DONOR}:clone .
cd clone/
tar -vxf server.tar.gz

# Compare kernels
clear; dpkg -l | grep -E "^\S+\s+linux-image"
grep "^linux-image" packages.selection

# Remove systemd??
apt-get update -qq
apt-get install -qq sysvinit-core sysvinit-utils
cp -v /usr/share/sysvinit/inittab /etc/inittab
echo -e 'Package: *systemd*\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd
# Schedule removal of systemd
echo "PATH=/usr/sbin:/usr/bin:/sbin:/bin
@reboot root apt-get purge -qq --auto-remove systemd >/dev/null;rm -f /etc/cron.d/withoutsystemd" > /etc/cron.d/withoutsystemd

# Normalize OS
../debian-image-normalize.sh

# Restore /etc
chmod -c 0755 ./etc
mv -vf /etc/ /root/etc && mv -vf ./etc /
# Inspect changes in /etc
while read -r F; do diff -u "${F/etc/root/etc}" "$F"; done < etc-blacklist.txt
# Restore blacklisted files to /etc
xargs -I%% cp -vf /root%% %% < etc-blacklist.txt
# Recreate homes
sed -ne 's/^\(\S\+\):x:1[0-9][0-9][0-9]:.*$/\1/p' /etc/passwd | xargs -n1 mkhomedir_helper
#tar -C /home/ -xvf ./homes.tar.gz
apt-get update -qq

# Kernel modules
ls -l /etc/modprobe.d/
# Network
editor /etc/network/interfaces
editor /etc/resolv.conf
# Disk
editor /etc/fstab
editor /etc/mdadm/mdadm.conf
# Devices
ls -l /etc/udev/
# Hostname:
read -r -e -p "Host name? " H
hostname "$H"
echo "$H" > /etc/hostname
echo "$H" > /etc/mailname
editor /etc/hosts
mkdir /etc/courier; echo "$H" > /etc/courier/me

# Check hardware again
clear; fdisk -l /dev/[svx]d?
cat /proc/mdstat
pvdisplay && lvs
ifconfig

# Restore packages
apt-get install -qq apt-transport-https apt-utils dselect debsums
dselect update
clear; debconf-set-selections < debconf.selections
# @FIXME Question type: error

# Reconfigure already installed packages
dpkg-reconfigure -f noninteractive dash
dpkg-reconfigure openssh-server && service ssh restart
dpkg-reconfigure -f noninteractive locales
rm -f /etc/timezone
dpkg-reconfigure -f noninteractive tzdata && service rsyslog restart
dpkg-reconfigure -f noninteractive unattended-upgrades

# Package blacklist
grep -E "^(open-vm-tools|linux-image|mdadm|lvm|grub|systemd)" packages.selection
dpkg -l | grep -E "^\S+\s+(open-vm-tools|linux-image|mdadm|lvm|grub|systemd)"

# Install packages
dpkg --clear-selections; dpkg --dry-run --set-selections < packages.selection
# Match these with the currently installed packages
editor packages.selection
dpkg --clear-selections; dpkg --set-selections < packages.selection
# Manual install
apt-get dselect-upgrade
apt-get install -f

# Check package intergrity and SSH
debsums -c
systemctl status
dpkg -l | grep "openssh-server" || echo 'no SSH !!!'
netstat -anp | grep "ssh" || echo 'no SSH !!!'
# LOG IN NOW WITHOUT LOGGING OUT


## Restore data dirs and special handling dirs

cd /usr/local/src/
git clone https://github.com/szepeviktor/debian-server-tools.git
apt-get install -y python python-dev gcc dialog libssl-dev libffi-dev ca-certificates
pip2 install certbot

chown -cR virtual:virtual /var/mail/*
cat /etc/courier/me

# Check services from server.yml
