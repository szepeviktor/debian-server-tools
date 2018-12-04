#!/bin/bash
#
# Check Debian OS: jessie 8.x netinst (essential, required, important) and standard packages.
#
# VERSION       :1.0.9
# DEPENDS       :apt-get install aptitude

# Generated lists
#
# - missing.pkgs
# - extra.pkgs
# - installed-by-size.pkgs

STANDARD_BLACKLIST="exim.*|procmail|bsd-mailx|mutt\
|nfs-common|rpcbind\
|intel-microcode|amd64-microcode\
|ftp|mlocate|texinfo|info|install-info|debian-faq|doc-debian"

OLD_PACKAGE_QUERY='?and(?installed, ?or(?version(~~squeeze), ?version(\+deb6), ?version(python2\.6), ?version(~~wheezy), ?version(\+deb7)))'
TILDE_VERSION="cloud-init|grub-common|grub-pc|grub-pc-bin|grub2-common|libgraphite2-3:amd64|intel-microcode"

export LC_ALL="C"
export DEBIAN_FRONTEND="noninteractive"
export APT_LISTCHANGES_FRONTEND="none"

APTI_SEARCH="aptitude --disable-columns --display-format %p search"

{
    ${APTI_SEARCH} '?and(?archive(stable), ?essential, ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(required), ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(important), ?not(?installed), ?architecture(native))'
    ${APTI_SEARCH} '?and(?archive(stable), ?priority(standard), ?not(?installed), ?architecture(native))' | grep -Evx "$STANDARD_BLACKLIST"
} 2>&1 | tee missing.pkgs | grep '.' && echo "Missing packages" 1>&2

{
    ${APTI_SEARCH} '?garbage' | sed -e 's/$/ # garbage/'
    ${APTI_SEARCH} '?broken' | sed -e 's/$/ # broken/'
    ${APTI_SEARCH} '?obsolete' | sed -e 's/$/ # obsolete/'
    ${APTI_SEARCH} "$OLD_PACKAGE_QUERY" | sed -e 's/$/ # old/'
    ${APTI_SEARCH} '?and(?installed, ?not(?origin(Debian)))' | sed -e 's/$/ # non-Debian/'
    #:ubuntu ${APTI_SEARCH} '?and(?installed, ?not(?origin(Ubuntu)))' | sed -e 's/$/ # non-Ubuntu/'
    dpkg -l | grep '\~[a-z]\+' | grep -E -v "^ii  (${TILDE_VERSION})\\s" | cut -c 1-55 | sed -e 's/$/ # tilde version/'
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
