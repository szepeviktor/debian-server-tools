#!/bin/bash
#
# Normalize Debian OS: jessie 8.x netinst (essential, required, important) and standard packages
#
# VERSION       :1.0.0
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
#       What to do on critical errors?
#       Where to log? stdout, stderr, file
#       Exclude from tilde-version: cloud-init grub-common grub-pc grub-pc-bin grub2-common libgraphite2-3 intel-microcode

STANDARD_BLACKLIST="exim.*|procmail|mutt|bsd-mailx|ftp|mlocate|nfs-common|rpcbind\
|texinfo|info|install-info|debian-faq|doc-debian\
|intel-microcode|amd64-microcode"

# Don't ever remove these
BOOT_PACKAGES="grub-pc|linux-image-amd64|firmware-linux-nonfree|usbutils|mdadm|lvm2\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sudo|cloud-init|cloud-initramfs-growroot\
|sysvinit|initramfs-tools|insserv|discover|systemd|libpam-systemd|systemd-sysv|dbus\
|extlinux|syslinux-common|elasticstack-container|waagent|scx|omi"

set -x -e

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"
export APT_LISTCHANGES_FRONTEND="none"
cd

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

for DEP in $(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p"); do
    REGEXP="$(sed -e 's;\([^a-z0-9]\);[\1];g' <<< "$DEP")"
    if aptitude why "$DEP" 2>&1 | grep -Eq "^i.. \S+\s+(Pre)?Depends( | .* )${REGEXP}( |$)"; then
        apt-mark auto "$DEP" || echo "[ERROR] Marking package ${DEP} failed." 1>&2
    fi
done

# Install standard packages

STANDARD_PACKAGES="$(aptitude --disable-columns search '?or(?essential, ?priority(required), ?priority(important), ?priority(standard))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST")"
#STANDARD_PACKAGES="$(aptitude --disable-columns search \
# '?and(?architecture(native), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' -F"%p" \
# | grep -Evx "$STANDARD_BLACKLIST")"
apt-get -qq -y install ${STANDARD_PACKAGES}

# Install missing recommended packages

MISSING_RECOMMENDS="$(aptitude --disable-columns search '?and(?reverse-recommends(?installed), ?version(TARGET), ?not(?installed))' -F"%p" \
 | grep -Evx "$STANDARD_BLACKLIST" || true)"
apt-get -qq -y install ${MISSING_RECOMMENDS}

# Remove non-standard packages

MANUALLY_INSTALLED="$(aptitude --disable-columns search \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' -F"%p" \
 | grep -Evx "$BOOT_PACKAGES" | tee removed.pkgs || true)"
apt-get purge -qq -y ${MANUALLY_INSTALLED}

# List what boot packages are installed

aptitude --disable-columns search '?and(?installed, ?not(?automatic))' -F"%p" \
 | grep -Ex "$BOOT_PACKAGES" | sed 's/$/ # boot/'

# Remove packages on standard-blacklist

apt-get purge -qq -y $(aptitude --disable-columns search '?installed' -F"%p" | grep -Ex "$STANDARD_BLACKLIST" || true)
# Exim bug
getent passwd Debian-exim &> /dev/null && deluser --force --remove-home Debian-exim
# Dummy MTA instead of Exim
apt-get install -qq -y lsb-invalid-mta
apt-get autoremove -qq --purge -y

# Do dist-upgrade finally

apt-get dist-upgrade -qq -y

# Check for missing packages

set +x +e
{
    aptitude --disable-columns search '?and(?essential, ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(required), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(important), ?not(?installed))' -F"%p"
    aptitude --disable-columns search '?and(?priority(standard), ?not(?installed))' -F"%p" | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep "." && echo "Missing packages" 1>&2 || true

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
    dpkg -l | grep "~[a-z]\+" | cut -c 1-55 | sed 's/$/ # tilde version/'
    # "-dev" versioned packages
    aptitude --disable-columns search '?and(?installed, ?name(-dev))' -F"%p" | sed 's/$/ # development/'
} 2>&1 | tee extra.pkgs | grep "." && echo "Extra packages" 1>&2 || true

# Check package integrity and cruft

apt-get install -qq -y debsums cruft > /dev/null
# Should be empty
debsums --all --changed 2>&1 | tee integrity.log | sed 's/$/ # integrity/'
cruft > cruft.log 2>&1

# List packages by size

dpkg-query -f '${Installed-size}\t${Package}\n' --show | sort -k 1 -n > installed-size.pkgs

exit 0
