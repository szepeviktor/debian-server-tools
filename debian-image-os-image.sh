#
# Normalize Debian packages
#
# Jessie 8.3 netinst (essential, required, important) and standard packages

# @TODO
#       What to do on critical error?
#       Where to log? stdout, stderr, files

STANDARD_BLACKLIST="exim.*|procmail|mutt|bsd-mailx|ftp|mlocate|nfs-common|rpcbind\
|texinfo|info|install-info|debian-faq|doc-debian\
|intel-microcode|amd64-microcode"

# Don't ever remove these
BOOT_PACKAGES="grub-pc|linux-image-amd64|firmware-linux-nonfree|usbutils|mdadm|lvm2\
|task-ssh-server|task-english|ssh|openssh-server|isc-dhcp-client|pppoeconf|ifenslave|ethtool|vlan\
|sudo|cloud-init|cloud-initramfs-growroot\
|sysvinit|initramfs-tools|insserv|discover|systemd|libpam-systemd|systemd-sysv|dbus\
|extlinux|syslinux-common|elasticstack-container|waagent|scx|omi"

set +e

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# APT

apt-get install -y -f
apt-get install -y lsb-release apt aptitude debian-archive-keyring
#apt-get install -y lsb-release apt aptitude ubuntu-keyring
apt-get autoremove --purge -y
# Purge packages that were removed but not purged
apt-get purge -y $(aptitude --disable-columns search '?config-files' -F"%p")

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
# Dummy MTA instead of exim
apt-get install -qq -y lsb-invalid-mta
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
