#!/bin/bash
#
# Normalize Debian OS: stretch 9.x netinst (essential, required, important) and standard packages.
#
# VERSION       :2.0.1
# DOCS          :https://www.debian.org/doc/manuals/aptitude/ch02s04s05.en.html
# DEPENDS       :apt-get install aptitude

# Generated lists
#
# - missing.pkgs
# - extra.pkgs
# - removed.pkgs
# - integrity.log
# - cruft.log
# - installed-by-size.pkgs

# @TODO
#   See https://sources.debian.net/src/upgrade-system/1.7.3.0/upgrade-system/

STANDARD_BLACKLIST="exim.*|procmail|bsd-mailx|mutt\
|nfs-common|rpcbind\
|intel-microcode|amd64-microcode\
|ftp|mlocate|texinfo|info|install-info|debian-faq|doc-debian"

# Don't ever remove these
BOOT_PACKAGES="debian-archive-keyring|lsb-release|ca-certificates|wget|apt|apt-utils|aptitude|aptitude-common|net-tools\
|grub-pc|grub-efi-amd64|extlinux|syslinux-common|linux-image-amd64|initramfs-tools\
|firmware-.*|usbutils|mdadm|lvm2|xfsprogs\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sysvinit|sysvinit-core|sysvinit-utils|initscripts|insserv|discover\
|systemd|libpam-systemd|systemd-sysv|dbus\
|open-vm-tools|open-vm-tools-dkms|dkms|sudo|cloud-init|cloud-initramfs-growroot\
|elasticstack-container|waagent|scx|omi"

OLD_PACKAGE_QUERY='?and(?installed, ?or(?version(~~squeeze), ?version(\+deb6), ?version(python2\.6), ?version(~~wheezy), ?version(\+deb7), ?version(~~jessie), ?version(\+deb8)))'
TILDE_VERSION="grub-common|grub-pc|grub-pc-bin|grub2-common|liblz4-1:amd64|os-prober|python-apt|python-apt-common|python3-apt|intel-microcode"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"
export APT_LISTCHANGES_FRONTEND="none"

APTI_SEARCH="aptitude --disable-columns --display-format %p search"

Info()
{
    # Informational messages displayed only during `set -x`
    # shellcheck disable=SC2188
    >/dev/null
}

set -e -x

mkdir "${HOME}/os-normalize"
cd "${HOME}/os-normalize/"

Info "List what boot packages are installed"

${APTI_SEARCH} '?installed' \
    | grep -Ex "$BOOT_PACKAGES" | sed -e 's/$/ # boot/' | tee boot.pkgs

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
tasksel --list-tasks | grep -v '^u ' || true
# shellcheck disable=SC2046
apt-get purge -qq $(${APTI_SEARCH} '?and(?installed, ?or(?name(^task-), ?name(^tasksel)))') #'
# grep -A 4 '^Template: ' /var/lib/dpkg/info/tasksel.templates
echo "tasksel tasksel/first multiselect" | debconf-set-selections -v
echo "tasksel tasksel/tasks multiselect ssh-server, standard" | debconf-set-selections -v
echo "tasksel tasksel/desktop multiselect" | debconf-set-selections -v
echo "tasksel tasksel/title title" | debconf-set-selections -v
apt-get install -qq tasksel
# This may take a while
tasksel --new-install

Info "Mark dependencies of standard packages as automatic"

set +x
for DEP in $(${APTI_SEARCH} \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))'); do
    REGEXP="$(sed -e 's#\([^a-z0-9]\)#[\1]#g' <<<"$DEP")"
    if aptitude why "$DEP" 2>&1 | grep -q -E "^i.. \\S+\\s+(Pre)?Depends( | .* )${REGEXP}( |\$)"; then
        apt-mark auto "$DEP" || echo "[ERROR] Marking package ${DEP} failed." 1>&2
    fi
done
set -x

Info "Install standard packages"

STANDARD_PACKAGES="$(${APTI_SEARCH} \
 '?and(?archive(stable), ?or(?essential, ?priority(required), ?priority(important), ?priority(standard)), ?architecture(native))' \
 | grep -Evx "$STANDARD_BLACKLIST")"
# shellcheck disable=SC2086
apt-get -qq install ${STANDARD_PACKAGES}

Info "Install missing recommended packages"

MISSING_RECOMMENDS="$(${APTI_SEARCH} \
 '?and(?reverse-recommends(?installed), ?version(TARGET), ?not(?installed), ?architecture(native))' | grep -Evx "$STANDARD_BLACKLIST" || true)"
# shellcheck disable=SC2086
apt-get -qq install ${MISSING_RECOMMENDS}
echo "$MISSING_RECOMMENDS" | xargs -r -L 1 apt-mark auto

Info "Remove non-standard packages"

# See override.${CODENAME}.main.gz at http://ftp.debian.org/debian/indices/
MANUALLY_INSTALLED="$(${APTI_SEARCH} \
 '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' \
 | grep -Evx "$BOOT_PACKAGES" | tee removed.pkgs || true)"
# shellcheck disable=SC2086
apt-get purge -qq ${MANUALLY_INSTALLED}

Info "Remove packages on standard-blacklist"

# shellcheck disable=SC2046
apt-get purge -qq $(${APTI_SEARCH} '?installed' | grep -Ex "$STANDARD_BLACKLIST" || true)
# Exim bug
getent passwd "Debian-exim" >/dev/null && deluser --force --remove-home "Debian-exim"
test -f /etc/aliases && rm /etc/aliases
test -d /var/spool/exim4 && rm -rf /var/spool/exim4
# Texinfo config
test -d /etc/texmf && rm -r /etc/texmf

Info "Do dist-upgrade finally"

apt-get dist-upgrade -qq
apt-get autoremove -qq --purge

Info "Check package integrity and cruft"

apt-get install -qq debsums cruft > /dev/null
# Should be empty
debsums --all --changed 2>&1 | sed -e 's/$/ # integrity/' | tee integrity.log
cruft --ignore /root >cruft.log 2>&1

Info "Check for missing and extra packages"

set +e +x

{
    ${APTI_SEARCH} '?and(?archive(stable), ?essential, ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(required), ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(important), ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(standard), ?not(?installed), ?architecture(native))' | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep "." && echo "Missing packages" 1>&2

{
    ${APTI_SEARCH} '?garbage' | sed -e 's/$/ # garbage/'
    ${APTI_SEARCH} '?broken' | sed -e 's/$/ # broken/'
    ${APTI_SEARCH} '?obsolete' | sed -e 's/$/ # obsolete/'
    ${APTI_SEARCH} "$OLD_PACKAGE_QUERY" | sed -e 's/$/ # old/'
    ${APTI_SEARCH} '?and(?installed, ?not(?origin(Debian)))' | sed -e 's/$/ # non-Debian/'
    #:ubuntu ${APTI_SEARCH} '?and(?installed, ?not(?origin(Ubuntu)))' | sed -e 's/$/ # non-Ubuntu/'
    dpkg -l | grep '\~[a-z]\+' | grep -Ev "^ii  (${TILDE_VERSION})\\s" | cut -c 1-55 | sed -e 's/$/ # tilde version/'
    # "-dev" versioned packages
    ${APTI_SEARCH} '?and(?installed, ?name(-dev))' | sed -e 's/$/ # development/'
    # Overridden priorities
    aptitude --disable-columns --display-format "%p %P" search \
        '?and(?installed, ?not(?automatic), ?not(?essential), ?not(?priority(required)), ?not(?priority(important)), ?not(?priority(standard)))' \
        | while read -r PKG_PRIO; do
            DPKG_PRIO="$(dpkg-query -s "${PKG_PRIO% *}" | grep '^Priority:' | cut -d " " -f 2)"
            test "$DPKG_PRIO" != "${PKG_PRIO#* }" && echo "${PKG_PRIO% *} # ${PKG_PRIO#* } <- ${DPKG_PRIO} override"
        done
} 2>&1 | tee extra.pkgs | grep '.' && echo "Extra packages" 1>&2

# List packages by size
dpkg-query --showformat='${Installed-size}\t${Package}\n' --show | sort -k 1 -n >installed-by-size.pkgs

exit 0
