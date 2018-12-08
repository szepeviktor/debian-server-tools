#!/bin/bash
#
# Quick & dirty batch build wrapper for producing "minbase" Debian images.
#
# AUTHOR        :Ed
# SOURCE        :https://bitbucket.org/EdBoraas/debian-docker
# URL           :https://hub.docker.com/r/eboraas/debootstrap/
# DEPENDS       :apt-get install docker.io debootstrap

# Set TAGPREFIX based on your desired naming; e.g.,
# for jdoe/debian:<suite> use
#     TAGPREFIX=jdoe/debian:
# and for jdoe/somerepo:debian-<suite> use
#     TAGPREFIX=jdoe/somerepo:debian-
TAGPREFIX="szepeviktor/debootstrap:minbase-"

# Set SUITES to the space-delimited list of suites you wish to build
declare -a SUITES=( oldstable stable testing experimental wheezy jessie stretch sid )

# Set PUSH to 0 (the default) to build without pushing, or
# set PUSH to 1 to push each image after it's built, or
# set PUSH to 2 to push the repo (TAGPREFIX up to the first colon) after
declare -i PUSH="0"

for SUITE in "${SUITES[@]}"; do
    /usr/share/docker.io/contrib/mkimage.sh -t "${TAGPREFIX}${SUITE}" \
        debootstrap --variant=minbase "${SUITE}" "http://http.debian.net/debian"
    if [ "$PUSH" -eq 1 ]; then
        /usr/bin/docker.io push "${TAGPREFIX}${SUITE}"
    fi
done

if [ "$PUSH" -eq 2 ]; then
    /usr/bin/docker.io push "$(cut -d ":" -f 1 <<<"${TAGPREFIX}${SUITE}")"
fi

echo "OK."
