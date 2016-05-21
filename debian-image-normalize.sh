#!/bin/bash
#
# Normalize Debian OS: jessie 8.x netinst (essential, required, important) and standard packages
#
# VERSION       :1.0.3
# DEPENDS       :apt-get install apt aptitude debian-archive-keyring

# Generated lists
#
# - missing.pkgs
# - extra.pkgs
# - removed.pkgs
# - integrity.log
# - cruft.log
# - installed-size.pkgs

# @TODO
#       Move -F"%p" to front
#       What to do on critical errors?
#       Where to log? stdout, stderr, *file

STANDARD_BLACKLIST="exim.*|procmail|mutt|bsd-mailx|ftp|mlocate|nfs-common|rpcbind\
|texinfo|info|install-info|debian-faq|doc-debian\
|intel-microcode|amd64-microcode"

# Don't ever remove these
BOOT_PACKAGES="grub-pc|grub-efi-amd64|extlinux|syslinux-common|linux-image-amd64|initramfs-tools\
|firmware-.*|usbutils|mdadm|lvm2|xfsprogs\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sysvinit|sysvinit-core|sysvinit-utils|insserv|discover\
|systemd|libpam-systemd|systemd-sysv|dbus\
|open-vm-tools|open-vm-tools-dkms|dkms|sudo|cloud-init|cloud-initramfs-growroot\
|elasticstack-container|waagent|scx|omi"

TILDE_VERSION="cloud-init|grub-common|grub-pc|grub-pc-bin|grub2-common|libgraphite2-3:amd64|intel-microcode"

set -x -e

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"
export APT_LISTCHANGES_FRONTEND="none"
mkdir ${HOME}/os-normalize; cd ${HOME}/os-normalize/

# List what boot packages are installed

aptitude --disable-columns search '?and(?installed, ?not(?automatic))' -F"%p" \
 | grep -Ex "$BOOT_PACKAGES" | sed 's/$/ # boot/' | tee boot.pkgs

# APT status

# Remove no longer needed packages
apt-get autoremove --purge -y
# Purge packages that were removed but not purged
apt-get purge -y $(aptitude --disable-columns search '?config-files' -F"%p")
# Clean package cache
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y
apt-get update -qq

# Reinstall tasks

debconf-show tasksel
#tasksel --list-tasks
apt-get purge -qq -y $(aptitude --disable-columns search '?and(?installed, ?or(?name(^task-), ?name(^tasksel)))' -F"%p") #'
echo "tasksel tasksel/first select" | debconf-set-selections -v
echo "tasksel tasksel/desktop multiselect" | debconf-set-selections -v
echo "tasksel tasksel/first multiselect ssh-server, standard" | debconf-set-selections -v
echo "tasksel tasksel/tasks multiselect ssh-server" | debconf-set-selections -v
apt-get install -qq -y tasksel
# May take a while
tasksel --new-install

# Mark dependencies of standard packages as automatic

set +x
for DEP in $(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p"); do
    REGEXP="$(sed -e 's;\([^a-z0-9]\);[\1];g' <<< "$DEP")"
    if aptitude why "$DEP" 2>&1 | grep -Eq "^i.. \S+\s+(Pre)?Depends( | .* )${REGEXP}( |$)"; then
        apt-mark auto "$DEP" || echo "[ERROR] Marking package ${DEP} failed." 1>&2
    fi
done
set -x

# Install standard packages

STANDARD_PACKAGES="$(aptitude --disable-columns search \
 '?and(?not(?obsolete), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST")"
#STANDARD_PACKAGES="$(aptitude --disable-columns search \
# '?and(?architecture(native), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' -F"%p" \
# | grep -Evx "$STANDARD_BLACKLIST")"
apt-get -qq -y install ${STANDARD_PACKAGES}

# Install missing recommended packages

MISSING_RECOMMENDS="$(aptitude --disable-columns search '?and(?reverse-recommends(?installed), ?version(TARGET), ?not(?installed))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST" || true)"
apt-get -qq -y install ${MISSING_RECOMMENDS}
echo "$MISSING_RECOMMENDS" | xargs -r -L 1 apt-mark auto

# Remove non-standard packages

MANUALLY_INSTALLED="$(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p" \
 | grep -Evx "$BOOT_PACKAGES" | tee removed.pkgs || true)"
apt-get purge -qq -y ${MANUALLY_INSTALLED}

# Remove packages on standard-blacklist

apt-get purge -qq -y $(aptitude --disable-columns search '?installed' -F"%p" | grep -Ex "$STANDARD_BLACKLIST" || true)
# Exim bug
getent passwd Debian-exim &> /dev/null && deluser --force --remove-home Debian-exim

# Do dist-upgrade finally

apt-get dist-upgrade -qq -y
apt-get autoremove -qq --purge -y

# Check package integrity and cruft

apt-get install -qq -y debsums cruft > /dev/null
# Should be empty
debsums --all --changed 2>&1 | tee integrity.log | sed 's/$/ # integrity/'
cruft > cruft.log 2>&1

set +e +x

# Check for missing packages

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
    #Ubuntu: aptitude --disable-columns search '?and(?installed, ?not(?origin(Ubuntu)))' -F"%p" | sed 's/$/ # non-Ubuntu/'
    dpkg -l | grep "~[a-z]\+" | grep -Ev "^ii  (${TILDE_VERSION})\s" | cut -c 1-55 | sed 's/$/ # tilde version/'
    # "-dev" versioned packages
    aptitude --disable-columns search '?and(?installed, ?name(-dev))' -F"%p" | sed 's/$/ # development/'
} 2>&1 | tee extra.pkgs | grep "." && echo "Extra packages" 1>&2

# List packages by size

dpkg-query -f '${Installed-size}\t${Package}\n' --show | sort -k 1 -n > installed-size.pkgs

exit 0
