#!/bin/bash
#
# Normalize Debian OS: jessie 8.x netinst (essential, required, important) and standard packages
#
# VERSION       :1.0.6
# DEPENDS       :apt-get install apt aptitude debian-archive-keyring

# Generated lists
#
# - missing.pkgs
# - extra.pkgs
# - removed.pkgs
# - integrity.log
# - cruft.log
# - installed-by-size.pkgs

# @TODO
#       What to do on critical errors?

STANDARD_BLACKLIST="exim.*|procmail|bsd-mailx|mutt\
|nfs-common|rpcbind\
|intel-microcode|amd64-microcode\
|ftp|mlocate|texinfo|info|install-info|debian-faq|doc-debian"

# Don't ever remove these
BOOT_PACKAGES="grub-pc|grub-efi-amd64|extlinux|syslinux-common|linux-image-amd64|initramfs-tools\
|firmware-.*|usbutils|mdadm|lvm2|xfsprogs\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sysvinit|sysvinit-core|sysvinit-utils|insserv|discover\
|systemd|libpam-systemd|systemd-sysv|dbus\
|open-vm-tools|open-vm-tools-dkms|dkms|sudo|cloud-init|cloud-initramfs-growroot\
|elasticstack-container|waagent|scx|omi"

OLD_PACKAGE_QUERY='?and(?installed, ?or(?version(~~squeeze), ?version(\+deb6), ?version(python2\.6), ?version(~~wheezy), ?version(\+deb7)))'
TILDE_VERSION="cloud-init|grub-common|grub-pc|grub-pc-bin|grub2-common|libgraphite2-3:amd64|intel-microcode"

Info() {
    # Informational messages displayed only during `set -x`
    > /dev/null
}

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"
export APT_LISTCHANGES_FRONTEND="none"

APTI_SEARCH="aptitude --disable-columns --display-format %p search"

set -x -e

mkdir "${HOME}/os-normalize"; cd "${HOME}/os-normalize/"

Info "List what boot packages are installed"

${APTI_SEARCH} '?and(?installed, ?not(?automatic))' \
 | grep -Ex "$BOOT_PACKAGES" | sed 's/$/ # boot/' | tee boot.pkgs

Info "APT status"

# Remove no longer needed packages
apt-get autoremove --purge -y
# Purge packages that were removed but not purged
# shellcheck disable=SC2046
apt-get purge -y $(${APTI_SEARCH} '?config-files')
# Clean package cache
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get clean
apt-get autoremove --purge -y
apt-get update -qq

Info "Reinstall tasks"

debconf-show tasksel
tasksel --list-tasks | grep -v "^u "
# shellcheck disable=SC2046
apt-get purge -qq -y $(${APTI_SEARCH} '?and(?installed, ?or(?name(^task-), ?name(^tasksel)))')
#tasksel --task-packages ssh-server; tasksel --task-packages standard '
echo "tasksel tasksel/first select" | debconf-set-selections -v
echo "tasksel tasksel/desktop multiselect" | debconf-set-selections -v
echo "tasksel tasksel/first multiselect ssh-server, standard" | debconf-set-selections -v
echo "tasksel tasksel/tasks multiselect ssh-server" | debconf-set-selections -v
apt-get install -qq -y tasksel
# May take a while
tasksel --new-install

Info "Mark dependencies of standard packages as automatic"

set +x
for DEP in $(${APTI_SEARCH} \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))'); do
    REGEXP="$(sed -e 's;\([^a-z0-9]\);[\1];g' <<< "$DEP")"
    if aptitude why "$DEP" 2>&1 | grep -Eq "^i.. \S+\s+(Pre)?Depends( | .* )${REGEXP}( |$)"; then
        apt-mark auto "$DEP" || echo "[ERROR] Marking package ${DEP} failed." 1>&2
    fi
done
set -x

Info "Install standard packages"

STANDARD_PACKAGES="$(${APTI_SEARCH} \
 '?and(?not(?obsolete), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' \
 | grep -Evx "$STANDARD_BLACKLIST")"
# Native arch.
#STANDARD_PACKAGES="$(${APTI_SEARCH} \
# '?and(?architecture(native), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)))' \
# | grep -Evx "$STANDARD_BLACKLIST")"
# shellcheck disable=SC2086
apt-get -qq -y install ${STANDARD_PACKAGES}

Info "Install missing recommended packages"

MISSING_RECOMMENDS="$(${APTI_SEARCH} \
 '?and(?reverse-recommends(?installed), ?version(TARGET), ?not(?installed))' | grep -Evx "$STANDARD_BLACKLIST" || true)"
# shellcheck disable=SC2086
apt-get -qq -y install ${MISSING_RECOMMENDS}
echo "$MISSING_RECOMMENDS" | xargs -r -L 1 apt-mark auto

Info "Remove non-standard packages"

MANUALLY_INSTALLED="$(${APTI_SEARCH} \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' \
 | grep -Evx "$BOOT_PACKAGES" | tee removed.pkgs || true)"
# shellcheck disable=SC2086
apt-get purge -qq -y ${MANUALLY_INSTALLED}

Info "Remove packages on standard-blacklist"

# shellcheck disable=SC2046
apt-get purge -qq -y $(${APTI_SEARCH} '?installed' | grep -Ex "$STANDARD_BLACKLIST" || true)
# Exim bug
getent passwd Debian-exim &> /dev/null && deluser --force --remove-home Debian-exim

Info "Do dist-upgrade finally"

apt-get dist-upgrade -qq -y
apt-get autoremove -qq --purge -y

Info "Check package integrity and cruft"

apt-get install -qq -y debsums cruft > /dev/null
# Should be empty
debsums --all --changed 2>&1 | sed 's/$/ # integrity/' | tee integrity.log
cruft > cruft.log 2>&1

set +e +x

Info "Check for missing packages"

{
    ${APTI_SEARCH} '?and(?essential, ?not(?installed))'
    ${APTI_SEARCH} '?and(?priority(required), ?not(?installed))'
    ${APTI_SEARCH} '?and(?priority(important), ?not(?installed))'
    ${APTI_SEARCH} '?and(?priority(standard), ?not(?installed))' | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep "." && echo "Missing packages" 1>&2

Info "Check for extra packages"

{
    ${APTI_SEARCH} '?garbage' | sed 's/$/ # garbage/'
    ${APTI_SEARCH} '?broken' | sed 's/$/ # broken/'
    ${APTI_SEARCH} '?obsolete' | sed 's/$/ # obsolete/'
    ${APTI_SEARCH} "$OLD_PACKAGE_QUERY" | sed 's/$/ # old/'
    ${APTI_SEARCH} '?and(?installed, ?not(?origin(Debian)))' | sed 's/$/ # non-Debian/'
    #Ubuntu: ${APTI_SEARCH} '?and(?installed, ?not(?origin(Ubuntu)))' | sed 's/$/ # non-Ubuntu/'
    dpkg -l | grep "\~[a-z]\+" | grep -Ev "^ii  (${TILDE_VERSION})\s" | cut -c 1-55 | sed 's/$/ # tilde version/'
    # "-dev" versioned packages
    ${APTI_SEARCH} '?and(?installed, ?name(-dev))' | sed 's/$/ # development/'
} 2>&1 | tee extra.pkgs | grep "." && echo "Extra packages" 1>&2

Info "List packages by size"

dpkg-query --showformat="\${Installed-size}\t\${Package}\n" --show | sort -k 1 -n > installed-by-size.pkgs

exit 0
