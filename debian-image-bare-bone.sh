#!/bin/bash
#
# Set up a Debian jessie system.
#


# Input data as valid YAML (cloud-init)
#
# - provider/virtualization type defaults:
#   - is_baremetal
#   - is_hypervisor
#   - is_virtual
# - per instance values:
#   - systemd or sysvinit


# Debian Installer steps (Expert Install) -> package sources/release
#
#  1. Default language and location (English/United States) -> users/lang
#  2. Locale (en_US.UTF-8) -> users/locale
#  3. Keyboard (American English) -> users/keyboard
#  4. Network (DHCP or static IP, DNS resolver, host name) -> kernel/network
#  5. Users (no root login, "debian" user, standard password) -> users/root, users/users
#  6. Timezone (use NTP, UTC) -> kernel/timezone
#  7. Disks (300MB boot part, use LVM: 2GB swap, 3GB root) -> hardware/disks,partitions,volumes
#  8. Base system (linux-image-amd64) -> kernel
#  8. APT sources: per country mirror, non-free and backports, no popcon -> package sources/APT sources
#  9. Tasksel (SSH + standard) -> packages/tasks
# 10. Boot loader (GRUB, no EFI) -> boot


# OS image
#
# - normalized image
# - normalization on first boot
# - clean up things from kernel messages


# First boot (OS image normalization and services)
#
# - package sources:
#   - release
#   - APT sources, sources.d/ (save original to /etc/apt/sources.list.orig)
# - boot:
#   - virtualization
#   - py/grub, syslinux
# - hardware:
#   - microcode
#   - disks, partitions, volumes
#   - sensors (SMART, temp, fan, volt)
#   - cpufreq/cpuidle
# - kernel:
#   - kernel modules, blacklist
#   - clock source, time synchronization
#   - timezone = UTC
#   - rng (entropy)
#   - irqbalance
#   - network
#   - netfilter (iptables, persistent)
# - init:
#   - remove systemd, -libpam-systemd, -dbus; deluser messagebus
# - users:
#   - lang
#   - keyboard
#   - locale
#   - root (dot files)
#   - SSH keys
#   - users (/etc/skel/, script on first login)
# - packages:
#   - tasks
#   - check STANDARD_BLACKLIST packages
#   - set up BOOT_PACKAGES packages
#   - configure installed (ess,req,imp,std) packages (prefer: debconf, add monit config, randomize cron times)
#   - create metapackages (equivs) only_on_virt, only_on_baremetal
#   - install services + configure (Linux daemons, ?etckeeper, needrestart, mail delivery methods, fail2ban, nscd, /root/dist-mod) (add monit config)
#     - mail (lsb-invalid-mta)
#
# Scripts
#
# - connect scripts to debian package names (e.g. login)
# - scripts should be able to: install, update, remove (?package management?)
# - system-backup.sh (debconf, etc, /root, user data, service data)
#
# Documentation
#
# - populate /root/server.yml for every installed component
#   - list of custom shell scripts + cron jobs

set -e

# Package sources

# Release
IMAGE_ARCH="amd64"
IMAGE_MACHINE="x86_64"
IMAGE_ID="Debian"
IMAGE_CODENAME="jessie"
LATEST_RELEASE="$(wget -qO- ftp://ftp.debian.org/debian/dists/${IMAGE_CODENAME}/Release|sed -ne 's;^Version: \(.*\)$;\1;p')"
# @TODO Or curl ...
CURRENT_ARCH="$(dpkg --print-architecture)"
CURRENT_MACHINE="$(uname --machine)"
if [ "$(dpkg-query --show -f='${Status}' lsb-release)" != "install ok installed" ] \
    || ! which lsb_release &> /dev/null; then
    apt-get update -qq
    apt-get install -qq -y -f lsb-release
    apt-mark auto lsb-release
fi
CURRENT_ID="$(lsb_release -s --id)"
CURRENT_CODENAME="$(lsb_release -s --codename)"
#CURRENT_RELEASE="$(cat /etc/debian_version)"
CURRENT_RELEASE="$(lsb_release -s --release)"
[ "$CURRENT_ARCH" == "$IMAGE_ARCH" ]
[ "$CURRENT_MACHINE" == "$IMAGE_MACHINE" ]
[ "$CURRENT_ID" == "$IMAGE_ID" ]
[ "$CURRENT_CODENAME" == "$IMAGE_CODENAME" ]


# APT sources
# Check Install-Recommends
#apt-get install -o APT::AutoRemove::RecommendsImportant=false
IMAGE_APTRECOMMENDS='APT::Install-Recommends "1";'
CURRENT_APTRECOMMENDS="$(apt-config dump APT::Install-Recommends)"
[ "$CURRENT_APTRECOMMENDS" == "$IMAGE_APTRECOMMENDS" ]
# Set sources
# @TODO Handle sources.list.d/
mv -v /etc/apt/sources.list /etc/apt/sources.list.orig
wget -nv -O /etc/apt/sources.list "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/${IMAGE_CODENAME}-azure.list"
apt-get update -qq
if [ "$CURRENT_RELEASE" != "$LATEST_RELEASE" ]; then
    apt-get dist-upgrade -qq -y -f
fi
# Fix broken packages
apt-get install -y -f
# Install dependencies
apt-get install -qq -y apt apt-utils aptitude debian-archive-keyring
#Ubuntu: apt-get install -qq -y apt apt-utils aptitude ubuntu-keyring
./debian-image-normalize.sh

# Boot

# Detect virtualization environment
apt-get -qq -y install virt-what
VIRT="$(virt-what)"
{
    echo "$VIRT" | sed 's/$/ # virtualization/'
    cat /proc/cmdline | sed 's/$/ # cmdline/'
    case "$VIRT" in
        openvz)
            grep -a "container=" /proc/1/environ | tr -d -c '[:print:]' | sed 's/$/ # init-env/'
            ;;
        xen|xen-domU|xen-hvm)
            if [ -e /sys/hypervisor/uuid ]; then
                # Xen UUID
                cat /sys/hypervisor/uuid | sed 's/$/ # xen-uuid/'
            fi
            if which xenstore-read &> /dev/null; then
                # Xen unique domain ID
                xenstore-read "/local/domain/$(xenstore-read "domid")/unique-domain-id" | sed 's/$/ # xen-domid/'
                # Xen details
                #xenstore-ls "/local/domain/$(xenstore-read "domid")"
            fi
            if [ -c /dev/mem ]; then
                # Xen type: HVM/PV-HVM/PV
                dmidecode -s system-product-name | sed 's/$/ # product-name/'
            fi
            ;;
        hyperv|vmware)
            if [ -c /dev/mem ]; then
                # HyperV UUID
                dmidecode -s system-uuid | sed 's/$/ # system-uuid/'
            fi
            ;;
    esac
} | tee virtualization.log
apt-get -qq -y purge virt-what



# Cloud init preparation

# RPCBind opens up port 111 to the Internet
apt-get purge -qq -y rpcbind nfs-common
# Xen VM monitoring through XenStore
wget http://mirror.1and1.com/software/local-updates/XenServer_Tools/Linux/xe-guest-utilities_6.5.0-1423_amd64.deb
dpkg -i xe-guest-utilities_*.deb
# Install sudo
apt-get install -y sudo
# Newer Cloud init
echo "cloud-init cloud-init/datasources multiselect NoCloud, ConfigDrive, None" | debconf-set-selections -v
apt-get install -y -t jessie-backports cloud-init cloud-utils cloud-initramfs-growroot
nano /etc/cloud/cloud.cfg.d/10_fakeconfigdrive.cfg

cat <<EOF
#cloud-config
hostname: myhostname
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA17M3bU3LidWotM25W5sM6GWIPt1M1HAG0Kk2rwu21r5oSZjqTyLbs5ClgjDTCZBmwFtWQTwHKy+bgOeD5J02TC2jX/VfDzhcjv8/XFdnr0PImf4SL3DTg6MW98tCM4jd8E0J2PVSk3UAi9wpGU9ZxoOp7vy6qKsHv/Vwd0MpU9nPraP/A56Ps2EYk6vd1FVAcraxScuxiEoAjaLrFrn7X0nTwgMKzxiyTW8OwF4PM/J5AHC3Np8VxlkyDkVbnw3DPVLVVJxCcjMuKzAy4zuphA+vc0FlSU1L4mSQ2k754btlu9saW6SgZqzkHB2LgDDjSW8pHXqEAxfNt/GiJ2jVDw== viktor-RSA-2048bit@20140520
packages:
  - htop
EOF

# Clear traces

apt-get clean
rm -rf /tmp/*
# Clear logs
#rm -rf /var/log/*.log
# Clear history for all users
history -c
#ssh $USER@$HOST -- rm .bash_history
systemctl poweroff

# Cloud init YAML

#  Network (DHCP or static IP, DNS resolver, host name)
- Change IP, set resolver, change hostname (/etc/hosts too)
#  Users (no root login, "debian" user, standard password)
- Rename "debian" user and change password
- Install an SSH key, disable password authentication
#  Disks (300MB boot part, use LVM: 2GB swap, 5GB root)
- Resize LVM partition to full disk, grow root lv, grow root fs
- Resize swap
# APT sources: country mirror, release,security,updates,backports
# SSH port
Port 33000
fail2ban
# Time sync
- Xen time or NTP/Chrony?
#   iptables -I INPUT -p udp --destination-port 123 -j REJECT
#   iptables -I INPUT -p udp --destination-port 323 -j REJECT

# Cloud init examples

- Fail2ban and disable DSA keys for SSH
- Separate /var vg
- Separate /home vg
- Change server locale, keyboard



# Next image: debian base (bare bone image + some pkgs)



# @TODO if Deb_check_pkgname() then Deb_install_pkgname() else Deb_remove_pkgname()
grub
linux-image-amd64 linux-headers-amd64 Custom-Kernel `dpkg -l|grep linux-` # Ubuntu linux-image-virtual
firmware-linux-nonfree
irqbalance
rng-tools haveged
fancontrol hddtemp lm-sensors sensord smartmontools ipmitools
console-setup keyboard-configuration kbd ...
mdadm
lvm2

# @TODO Add to BOOT_PACKAGES
bridge-utils
isc-dhcp-client
pppoeconf
ifenslave
optional: sysvinit or systemd
resolvconf
acpi acpid (acpid necessary for UpCloud)
cloud-init cloud-initramfs-growroot
#cloud-image-utils cloud-initramfs-copymods cloud-initramfs-dyn-netconf
#snmpd
#vmware-tools-services vmware-tools-user /usr/bin/vmware-toolbox-cmd
#open-vm-tools open-vm-tools-dkms
#xe-guest-utilities
#xenstore-utils
intel-microcode amd64-microcode
cron (rendomize)

# On hypervisors?

# Install BASIC packages
sudo
aptitude
apt-transport-https
ca-certificates
iproute2
ipset
most
lftp
htop
mc
lynx
# @TODO etckeeper dstat ?ethstatus

cloud: https://docs.saltstack.com/en/latest/topics/cloud/index.html

https://docs.saltstack.com/en/latest/topics/best_practices.html

master: https://docs.saltstack.com/en/latest/topics/installation/debian.html

