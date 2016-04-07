#!/bin/bash --version
#
# Set up a Debian jessie system.
#
# Jessie 8.3 netinst (essential, required, important) and standard packages

# Debian Installer steps (Expert Install)
#
#  1. Default language and location (English/United States)
#  2. Locale (en_US.UTF-8)
#  3. Keyboard (American English)
#  4. Network (DHCP or static IP, DNS resolver, host name)
#  5. Users (no root login, "debian" user, standard password)
#  6. Timezone (use NTP, UTC)
#  7. Disks (300MB boot part, use LVM: 2GB swap, 3GB root)
#  8. Base system (linux-image-amd64)
#  8. APT sources: per country mirror, non-free and backports, no popcon
#  9. Tasksel (SSH + standard)
# 10. Boot loader (GRUB, no EFI)

set +e

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# APT

apt-get install -y -f
apt-get install -y lsb-release apt  aptitude debian-archive-keyring
#apt-get install -y lsb-release apt  aptitude ubuntu-keyring
apt-get autoremove --purge -y
# Purge packages that were removed but not purged
apt-get purge -y $(aptitude --disable-columns search '?config-files' -F"%p")

# Virtualization environment

#apt-get -qq -y install virt-what && virt-what
#grep -a "container=" /proc/1/environ
#cat /proc/cmdline
#cat /sys/hypervisor/uuid # Xen UUID
#dmidecode -s system-uuid # HyperV

# Distribution check

if dpkg-query --show -f='${Status}' lsb-release &> /dev/null; then
    #apt-get install -qq -y lsb-release && apt-mark auto lsb-release
    lsb_release -s -i # == Debian
    lsb_release -s -c # == jessie
    lsb_release -s -r # == "8\.[0-9]"
else
    cat /etc/debian_version
fi

# APT config and sanity check

# Check Install-Recommends
apt-config dump APT::Install-Recommends # == "1"
# @FIXME apt-get install -o APT::AutoRemove::RecommendsImportant=false

# No upgrade yet!

# Clean package cache
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y

# Set sources
mv -v /etc/apt/sources.list /etc/apt/sources.list.orig
# @TODO Detect repos in /etc/apt/sources.list.d/
wget -nv -O /etc/apt/sources.list "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/sources-cloudfront.list"
#nano /etc/apt/sources.list
apt-get update -qq -y
# Maybe an update is available
apt-get install -qq -y lsb-release apt aptitude debian-archive-keyring
#apt-get install -qq -y lsb-release apt aptitude ubuntu-keyring

# Reinstall tasks

debconf-show tasksel
apt-get purge -qq -y $(aptitude --disable-columns search '?and(?installed, ?or(?name(^task-), ?name(^tasksel)))' -F"%p") #'
echo "tasksel tasksel/first select " | debconf-set-selections -v
echo "tasksel tasksel/desktop multiselect" | debconf-set-selections -v
echo "tasksel tasksel/first multiselect ssh-server, standard" | debconf-set-selections -v
echo "tasksel tasksel/tasks multiselect ssh-server" | debconf-set-selections -v
apt-get install -qq -y tasksel
# May take a while
tasksel --new-install

# Mark dependencies of standard packages as automatic

for DEP in $(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p"); do
    REGEXP="$(sed -e 's;\([^a-z0-9]\);[\1];g' <<< "$DEP")"
    if aptitude why "$DEP" 2>&1 | grep -Eq "^i.. \S+\s+(Pre)?Depends( | .* )${REGEXP}( |$)"; then
        apt-mark auto "$DEP" || echo "[ERROR] Marking package ${DEP} failed." 1>&2
    fi
done

# Install standard packages

STANDARD_BLACKLIST="exim.*|procmail|mutt|bsd-mailx|ftp|mlocate|nfs-common|rpcbind|texinfo|info|install-info|debian-faq|doc-debian\
|intel-microcode|amd64-microcode"
# Don't ever remove these
BOOT_PACKAGES="grub-pc|linux-image-amd64|firmware-linux-nonfree|usbutils|mdadm|lvm2\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sudo|cloud-init|cloud-initramfs-growroot\
|sysvinit|initramfs-tools|insserv|discover|systemd|libpam-systemd|systemd-sysv|dbus\
|extlinux|syslinux-common|elasticstack-container|waagent|scx|omi"
STANDARD_PACKAGES="$(aptitude --disable-columns search '?or(?essential, ?priority(required), ?priority(important), ?priority(standard))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST")"
#STANDARD_PACKAGES="$(aptitude --disable-columns search \
# '?and(?architecture(native), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' -F"%p" \
# | grep -Evx "$STANDARD_BLACKLIST")"
apt-get -qq -y install ${STANDARD_PACKAGES}

# Install missing recommended packages

MISSING_RECOMMENDS="$(aptitude --disable-columns search '?and(?reverse-recommends(?installed), ?version(TARGET), ?not(?installed))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST")"
apt-get -qq -y install ${MISSING_RECOMMENDS}

# Remove non-standard packages

MANUALLY_INSTALLED="$(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p" \
 | grep -Evx "$BOOT_PACKAGES")"
apt-get purge -qq -y ${MANUALLY_INSTALLED}

# List what boot packages are installed

aptitude --disable-columns search '?and(?installed, ?not(?automatic))' -F"%p" \
 | grep -Ex "$BOOT_PACKAGES" | sed 's/$/ # boot/'

# Remove packages on standard-blacklist

apt-get purge -qq -y $(aptitude --disable-columns search '?installed' -F"%p" | grep -Ex "$STANDARD_BLACKLIST")
# Exim bug
getent passwd Debian-exim &> /dev/null && deluser --force --remove-home Debian-exim
apt-get autoremove -qq --purge -y
# Do dist-upgrade finally
apt-get dist-upgrade -qq -y

# Check for missing packages

cd
{
    aptitude --disable-columns search '?and(?essential, ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(required), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(important), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(standard), ?not(?installed))' -F"%p" | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep "." && echo "Missing packages" 1>&2

# Check for extra packages

{
    aptitude --disable-columns search '?garbage' -F"%p" | sed 's/$/ # garbage/'
    aptitude --disable-columns search '?broken' -F"%p" | sed 's/$/ # broken/'
    aptitude --disable-columns search '?obsolete' -F"%p" | sed 's/$/ # obsolete/'
    aptitude --disable-columns search \
     '?and(?installed, ?or(?version(~~squeeze), ?version(\+deb6), ?version(python2\.6), ?version(~~wheezy), ?version(\+deb7)))' -F"%p" \
     | sed 's/$/ # old/'
    aptitude --disable-columns search '?and(?installed, ?not(?origin(Debian)))' -F"%p" | sed 's/$/ # non-Debian/'
    #aptitude --disable-columns search '?and(?installed, ?not(?origin(Ubuntu)))' -F"%p" | sed 's/$/ # non-Ubuntu/'
    # @TODO Exclude: cloud-init grub-common grub-pc grub-pc-bin grub2-common libgraphite2-3 intel-microcode
    dpkg -l | grep "~[a-z]\+" | cut -c 1-55 | sed 's/$/ # tilde version/'
    # "-dev" versioned packages
    aptitude --disable-columns search '?and(?installed, ?name(-dev))' -F"%p" | sed 's/$/ # development/'
} 2>&1 | tee extra.pkgs | grep "." && echo "Extra packages" 1>&2

# Check package integrity and cruft

apt-get install -qq -y debsums cruft
# Should be empty
debsums -ac 2>&1 | sed 's/$/ # integrity/'
cruft 2>&1 | tee cruft.log

# List packages by size

dpkg-query -f '${Installed-size}\t${Package}\n' --show | sort -k 1 -n > installed.pkgs

exit 0


# OPTIONAL: Remove systemd, -libpam-systemd
# ?? -dbus; deluser messagebus


# Cloud init

# RPCBind opens up port 111 to the Internet
apt-get purge -qq -y rpcbind nfs-common
# Newer Cloud init
echo "cloud-init cloud-init/datasources multiselect NoCloud, ConfigDrive, None" | debconf-set-selections -v
apt-get install -t jessie-backports cloud-init cloud-utils cloud-initramfs-growroot
# Clear traces
apt-get clean
rm -rf /tmp/* /tmp/.*
# Clear logs
#rm -rf /var/log/*.log
# For all users
history -c
systemctl poweroff
# ?? mount image after poweroff

# SSH port
Port 33000
#  Network (DHCP or static IP, DNS resolver, host name)
- Change IP, set resolver, change hostname (/etc/hosts too)
#  Users (no root login, "debian" user, standard password)
- Rename "debian" user and change password
- Install an SSH key, disable password authentication
#  Time sync
- Xen time or Chrony?
#  Disks (300MB boot part, use LVM: 2GB swap, 5GB root)
- Resize LVM partition to full disk, grow root lv, grow root fs
- Resize swap
#  APT sources: per country mirror, non-free and backports, linux-image-amd64, no popcon
#  SSH

# Cloud init examples

- Fail2ban and disable DSA keys for SSH
- Separate /var vg
- Separate /home vg
- Change server locale, keyboard


- ssh 42000 + fail2ban
- 
- clean up things from kernel messages
- cloud-init/ jessie-backports

Next image: debian base
- 

# First steps of customization

1. Revisit STANDARD_BLACKLIST packages
1. Check BOOT_PACKAGES packages
1. Add extra repos
1. Install "Basic" packages

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

# @TODO Hypervisors?

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

