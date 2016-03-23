#!/bin/bash --version
#
# Set up a standard Debian jessie system.
#

set +e

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Virtualization check

apt-get -qq -y install virt-what && virt-what; grep -a "container=" /proc/1/environ

# Distribution check

# apt-get install -qq -y lsb-release && apt-mark auto lsb-release ???
apt-get -qq -y install lsb-release
lsb_release -s -i # == Debian
lsb_release -s -c # == jessie
lsb_release -s -r # == "8\.[0-9]"

# APT config and sanity check

# Check Install-Recommends
apt-config dump APT::Install-Recommends # == "1"
# @FIXME apt-get install -o APT::AutoRemove::RecommendsImportant=false
apt-get install -qq -f
apt-get install -qq -y apt debian-archive-keyring aptitude
#ubuntu-keyring
apt-get autoremove -qq --purge -y
# @TODO Purge packages that were removed but not purged
#apt-get purge -qq -y $(aptitude --disable-columns search '?config-files' -F"%p")
# No upgrade yet!
# Clean package cache
apt-get clean -qq
rm -rf /var/lib/apt/lists/*
apt-get clean -qq
apt-get autoremove -qq --purge -y
# Set sources
mv -v /etc/apt/sources.list /etc/apt/sources.list.orig
# @TODO Detect repos in /etc/apt/sources.list.d/
wget -nv -O /etc/apt/sources.list "https://github.com/szepeviktor/debian-server-tools/raw/master/package/apt-sources/sources-cloudfront.list"
#nano /etc/apt/sources.list
apt-get update -qq -y
# Maybe an update is available
apt-get install -qq -y apt debian-archive-keyring aptitude
#ubuntu-keyring

# Reinstall tasks

apt-get purge -qq -y $(aptitude --disable-columns search '?and(?installed, ?or(?name(^task-), ?name(^tasksel)))' -F"%p") #'
echo "tasksel tasksel/first select " | debconf-set-selections -v
echo "tasksel tasksel/desktop multiselect" | debconf-set-selections -v
echo "tasksel tasksel/first multiselect ssh-server, standard" | debconf-set-selections -v
echo "tasksel tasksel/tasks multiselect ssh-server" | debconf-set-selections -v
apt-get install -qq -y tasksel
#debconf-show tasksel
# May take long time
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

STANDARD_BLACKLIST="exim.*|procmail|mutt|bsd-mailx|at|ftp|mlocate|nfs-common|rpcbind|texinfo|info|install-info|debian-faq|doc-debian"
# Don't ever remove these
BOOT_PACKAGES="grub-pc|linux-image-amd64|firmware-linux-nonfree|usbutils|mdadm|lvm2|extlinux|syslinux-common\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sudo|cloud-init|cloud-initramfs-growroot\
|sysvinit|initramfs-tools|insserv|discover|systemd|libpam-systemd|systemd-sysv|dbus\
|elasticstack-container"
STANDARD_PACKAGES="$(aptitude --disable-columns search '?or(?essential, ?priority(required), ?priority(important), ?priority(standard))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST")"
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

# Remove packages on standard-blacklist

apt-get purge -qq -y $(aptitude --disable-columns search '?installed' -F"%p" | grep -Ex "$STANDARD_BLACKLIST")
# Exim bug
getent passwd Debian-exim &> /dev/null && deluser --force --remove-home Debian-exim
apt-get autoremove -qq --purge -y
apt-get dist-upgrade -qq -y

# Check for missing packages

{
    aptitude --disable-columns search '?and(?essential, ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(required), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(important), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(standard), ?not(?installed))' -F"%p" | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep -q "." && echo "Missing packages" 1>&2

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
    # @TODO Whitelist + report only: cloud-init grub-common grub-pc grub-pc-bin grub2-common libgraphite2-3
    #dpkg -l | grep "~[a-z]\+"
    # @TODO Remove auto-installed "-dev" packages
    #aptitude --disable-columns search '?and(?installed, ?name(-dev))' -F"%p" | sed 's/$/ # development/'
} 2>&1 | tee extra.pkgs | grep -q "." && echo "Extra packages" 1>&2

# Log cruft

apt-get install -qq -y debsums cruft
{ debsums -ac; cruft; } > debsums-cruft.log 2>&1

# List packages by size

dpkg-query -f '${Installed-size}\t${Package}\n' --show | sort -k 1 -n > installed.pkgs

exit 0


# OPTIONAL: Remove systemd, -libpam-systemd
# ?? -dbus; deluser messagebus

# Check in order of Debian Installer steps

1. System language+country
1. Locale
1. Keyboard
1. TZ
1. Network
1. Hostname
1. Users: root, 1st-user
1. popcon
1. Grub or other boot loader

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

