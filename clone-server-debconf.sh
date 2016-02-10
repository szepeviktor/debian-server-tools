#!/bin/bash --version
#
# Clone a server by reinstalling packages and copying settings.
#

exit 0

# Save on the "donor"

# Create etc-blacklist.txt from these
/etc/modprobe.d
/etc/network/interfaces
/etc/fstab
/etc/mdadm/mdadm.conf
/etc/udev
/etc/hostname
/etc/hosts
/etc/resolv.conf
/etc/mailname
/etc/courier/me
while read -r F; do find ${F} -type f; done < exclude.list > etc-blacklist.txt
ls /etc/ssh/ssh_host_*_key* >> etc-blacklist.txt

apt-get install -y debconf-utils
cd /var/backups/
debconf-get-selections > debconf.selections
dpkg --get-selections > packages.selection
tar --exclude-from=etc-blacklist.txt \
    -vczf server.tar.gz debconf.selections packages.selection etc-blacklist.txt /etc/*


# Restore on the "clone"

# Check hardware
fdisk -l /dev/sd?
cat /proc/mdstat
pvdisplay && lvs
ifconfig

# Clean package cache
apt-get clean
rm -vrf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Compare kernels
dpkg -l | grep -E "^\S+\s+linux-"
grep "^linux-image" packages.selection

# Remove systemd
apt-get update
apt-get install -y apt-transport-https apt-listchanges apt-utils dselect
dpkg -s systemd &> /dev/null && apt-get install -y sysvinit-core sysvinit sysvinit-utils
read -s -p 'Ctrl + D to reboot ' || reboot
apt-get remove -y --purge --auto-remove systemd
echo -e 'Package: *systemd*\nPin: origin ""\nPin-Priority: -1' > /etc/apt/preferences.d/systemd

# Restore /etc
cd /root/
tar -vxf server.tar.gz
chmod -c 0755 ./etc
mv -vf /etc/ /root/etc-old
mv -vf ./etc /

# Inspect changes in /etc
while read -r F; do diff -u "${F/etc/etc-old}" "$F"; done < etc-blacklist.txt

# Check hardware again
fdisk -l /dev/sd?
cat /proc/mdstat
pvdisplay && lvs
ifconfig

# Restore packages
dselect update
debconf-set-selections < debconf.selections
# @TODO Question type: error

# Package blacklist
grep -E "^(vmware|linux-image|mdadm|lvm|grub|systemd)" packages.selection
dpkg -l | grep -E "^\S+\s+(vmware|linux-image|mdadm|lvm|grub|systemd)"
# Match these with the currently installed packages
editor packages.selection

# Install packages
dpkg --clear-selections && dpkg --set-selections < packages.selection
apt-get dselect-upgrade -y
debsums -c
dpkg -l | grep "ssh" || echo 'no SSH !!!'
netstat -anp | grep "ssh" || echo 'no SSH !!!'

# Recreate homes
sed -ne 's/^\(\S\+\):x:1[0-9][0-9][0-9]:.*$/\1/p' /etc/passwd | xargs -n1 mkhomedir_helper

# Check services from server.yml

Data dirs:

/etc (from tar)
/opt
/root
/srv
/usr/local
/var
/var/lib/mysql
/var/cache
/var/mail
/var/spool
/var/tmp
(recreate dirs ??? owner,perms)

Special handling:

/home
/var/mail
/var/lib/mysql
/media/backup
