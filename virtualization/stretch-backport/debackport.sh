#!/bin/bash
#
# Backport a Debian package.
#
# DOCKER        :szepeviktor/stretch-backport
# VERSION       :0.2.5
# REFS          :http://backports.debian.org/Contribute/#index6h3
# DOCS          :https://wiki.debian.org/SimpleBackportCreation

# A) Build from source package name/release codename
#
# Get source package name:
#     apt-get source --dry-run $PACKAGE|grep "^Fetch source"
#
# B) Build from .dsc file URL
#
# Get the .dsc file at
#     https://www.debian.org/distrib/packages#search_packages
#
# C) Build from .git URL
#
# See https://anonscm.debian.org/cgit/
#
# Hooks
#
# 0. Install all Debian packages from /opt/results/
# 1. init - Before everything else
# 2. source - Provide custom source, should change to source directory and set CHANGELOG_MSG
# 3. pre-deps - Just before dependency installation
# 4. changes - Custom changelog entry
# 5. post-build - After build
#
# Package versioning
#     ${UPSTREAM_VERSION}[-${DEBIAN_REVISION}]~bpo${DEBIAN_RELEASE}+${BUILD_INT}

export DEBEMAIL="Viktor Szépe <viktor@szepe.net>"

ARCHIVE_URL="http://debian-archive.trafficmanager.net/debian"
#:ubuntu ARCHIVE_URL="http://archive.ubuntu.com/ubuntu"

ALLOW_UNAUTH="--allow-unauthenticated"

Error()
{
    local RET="$1"

    shift
    echo "ERROR: ${*}" 1>&2
    exit "$RET"
}

Execute_hook()
{
    local HOOK="debackport-${1}"

    if [ ! -r "/opt/results/${HOOK}" ]; then
        return 0
    fi

    # shellcheck disable=SC1090
    if source "/opt/results/${HOOK}"; then
        return 0
    else
        echo "HOOK ${HOOK} error: ${?}" 1>&2
        return 1
    fi
}

set -e

if [ -z "$PACKAGE" ]; then
    Error 1 'Usage:  docker run --rm --tty --volume /opt/results:/opt/results --env PACKAGE="openssl/testing" szepeviktor/stretch-backport'
fi

# Only for amd64
if [ "$(uname -m)" != x86_64 ]; then
    Error 2 "Tested only on amd64"
fi

CURRENT_RELEASE="$(lsb_release -s --codename)"

# Hook: init (e.g. set -x)
Execute_hook init

# Install .deb dependencies
sudo dpkg -R -i /opt/results/ || true
sudo apt-get update -qq
sudo apt-get install -y -f

if [ "${PACKAGE%.dsc}" != "$PACKAGE" ]; then
    # From .dsc URL
    dget --extract ${ALLOW_UNAUTH} "$PACKAGE"
    cd "$(basename "$PACKAGE" | cut -d "_" -f 1)-"*
    CHANGELOG_MSG="Built from DSC file: ${PACKAGE}"
elif [ "${PACKAGE%.git}" != "$PACKAGE" ]; then
    # From .git URL
    git clone "$PACKAGE"
    PACKAGE_NAME="$(basename "$PACKAGE" | cut -d "." -f 1)"
    cd "$PACKAGE_NAME"
    git checkout origin/pristine-tar
    # git --no-pager log -1 --pretty="%B"
    ORIG_TAG="$(git tag --list "upstream/*" | tail -n 1)"
    ORIG_VERSION="$(echo "$ORIG_TAG" | cut -d "/" -f 2)"
    git checkout "$ORIG_TAG"
    tar -czf "../${PACKAGE_NAME}_${ORIG_VERSION}.orig.tar.gz" .
    git checkout origin/master
    CHANGELOG_MSG="Built from git: ${PACKAGE}"
elif [ "${PACKAGE//[^\/]/}" == "/" ]; then
    # From source "package name/release codename"
    RELEASE="${PACKAGE#*/}"
    {
        echo "deb ${ARCHIVE_URL} ${RELEASE} main"
        echo "deb-src ${ARCHIVE_URL} ${RELEASE} main"
        # Release updates if available
        if wget -q --spider "${ARCHIVE_URL}/dists/${RELEASE}-updates/"; then
            echo "deb ${ARCHIVE_URL} ${RELEASE}-updates main"
            echo "deb-src ${ARCHIVE_URL} ${RELEASE}-updates main"
        fi
        # Security updates if available
        if wget -q --spider "http://security.debian.org/dists/${RELEASE}/updates/"; then
            echo "deb http://security.debian.org/ ${RELEASE}/updates main"
            echo "deb-src http://security.debian.org/ ${RELEASE}/updates main"
        fi
    } | sudo tee -a /etc/apt/sources.list
    sudo apt-get update -qq
    apt-get source "$PACKAGE"
    # "dpkg-source: info: extracting pkg in pkg-1.0.0"
    cd "${PACKAGE%/*}-"*
    CHANGELOG_MSG="Built from ${PACKAGE}"
else
    # From a custom source
    # Should change to source directory and set CHANGELOG_MSG
    Execute_hook source
    if [ ! -d "debian" ] || [ -z "$CHANGELOG_MSG" ]; then
        Error 3 "Custom source not available"
    fi
fi

# Hook: pre-deps (e.g. install dependencies from backports)
Execute_hook pre-deps

# Remove version number constraints and alternatives
DEPENDENCIES="$(dpkg-checkbuilddeps 2>&1 \
    | sed -e 's/^.*Unmet build dependencies: //' -e 's/ ([^)]\+)//g' -e 's/\(\S\+\)\( | \S\+\)\+/\1/g')"
if [ -n "$DEPENDENCIES" ]; then
    # shellcheck disable=SC2086
    sudo apt-get install -y ${DEPENDENCIES}
fi

# Double check
dpkg-checkbuilddeps

# Hook: changes (e.g. dch --edit, edit files, debcommit --message $TEXT --all)
ORIG_HASH="$(md5sum debian/changelog)"
if ! Execute_hook changes || echo "$ORIG_HASH" | md5sum --status -c - ; then
    # If 'changes' hook fails/is missing or does nothing to changelog
    dch --bpo --distribution "${CURRENT_RELEASE}-backports" "$CHANGELOG_MSG"
fi

dpkg-buildpackage -us -uc

# Hook: post-build (e.g. sign and upload)
Execute_hook post-build

cd ../
lintian --display-info --display-experimental --pedantic --show-overrides ./*.deb || true
sudo cp -av ./*.deb /opt/results/

echo "OK."
