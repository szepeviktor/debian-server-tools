#!/bin/bash --version
#
# Clone a server by reinstalling packages and copying settings.
#

exit 0

# Save on the "donor"
apt-get install -y debconf-utils
cd /var/backups/
debconf-get-selections > debconf.selections
dpkg --get-selections > packages.selection
tar --exclude=/etc/network/interfaces -vczf server.tar.gz debconf.selections packages.selection /etc/*


# Restore on the "clone"

# Sanitize packages
# See: ${D}/debian-setup.sh

# Clean package cache
apt-get clean
rm -vrf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Restore /etc
cd /root/
tar -vxf server.tar.gz
chmod -c 0755 ./etc
mv -vf /etc/ /etc-old
mv -vf ./etc /

# Changes in /etc
cd /etc/network/
cat /etc/hostname
fdisk -l /dev/sd?
cat /etc/fstab /etc/mdadm/mdadm.conf
cat /etc/apt/sources.list
cat /etc/mailname /etc/courier/me

# Remove systemd
apt-get update
dpkg -s systemd &> /dev/null && apt-get install -y sysvinit-core sysvinit sysvinit-utils
read -s -p 'Ctrl + D to reboot ' || reboot
apt-get remove -y --purge --auto-remove systemd
echo -e 'Package: *systemd*\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd

# Kernel
dpkg -l | grep "\slinux-"
grep "^linux-image" packages.selection

# Filesystems
# lvm, mdadm ...
cat /proc/mdstat
pvdisplay

# Restore packages
apt-get install -y dselect && dselect update
debconf-set-selections < debconf.selections
grep -E "vmware|linux-image" packages.selection
# Fix kernel, remove vmware
editor packages.selection
dpkg --clear-selections && dpkg --set-selections < packages.selection
apt-get dselect-upgrade -y
dpkg -l|grep "ssh"

See: services.list

Data dirs:

- /etc (from tar)
- /opt
- /root
- /srv
- /usr/local
- /var
- /var/lib/mysql
- /var/cache
- /var/mail
- /var/spool
- /var/tmp
- (recreate dirs ??? owner,perms)

Special handling:

- /home
- /var/mail
- /var/lib/mysql
- /media/backup

