#!/bin/bash
#
# Retrieve the .dsc file in three ways.
#
# VERSION       :0.2.0
# DATE          :2018-12-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/deb-get-dsc.sh
# DEPENDS       :apt-get install xmlstarlet


SUITE="testing"
SUITE_NAME="jessie"
REPO="http://http.debian.net/debian"
PTS_URL="http://qa.debian.org/cgi-bin/dcontrol"

hack_url()
{
    local PKG="$1"
    local DSCURL

    DSCURL="$(wget -qO- "https://packages.debian.org/${SUITE}/${PKG}" | grep -o 'http.*\.dsc">\[' | cut -d'"' -f1)"

    if [ -z "$DSCURL" ]; then
        echo "no .dsc" 1>&2
        return 1
    else
        echo "$DSCURL"
    fi
}

rdf_url()
{
    # Only source packages
    local PKG="$1"
    local DIRLEN="1"

    test "${PGK:0:3}" == lib && DIRLEN="4"

    wget -q -O- "http://packages.qa.debian.org/${PKG:0:DIRLEN}/${PKG}.html" \
        | grep -o 'http://packages\.qa\.debian\.org/.*/.*\.rdf'
}

dsc_url()
{
    local RDF
    local RDF_TESTING_VAL
    local RDF_TESTING_ASSET
    local RFD_DSC_PACKAGE

    RDF="$(rdf_url "$1" | wget -qO- -i-)"
    test -z "$RDF" && return 1

    # Find testing
    RDF_TESTING_VAL="http://www.debian.org/releases/${SUITE}#distribution"
    RDF_TESTING_ASSET="$(echo "$RDF" | xmlstarlet sel -t -v 'rdf:RDF/rdf:Description[@rdf:about="'"$RDF_TESTING_VAL"'"]/admssw:includedAsset/@rdf:resource')"

    # Find testing's dsc
    RFD_DSC_PACKAGE="$(echo "$RDF" | xmlstarlet sel -t -v '/rdf:RDF/admssw:SoftwareRelease[@rdf:about="'"$RDF_TESTING_ASSET"'"]/admssw:package/@rdf:resource')"

    # Get dsc URL
    echo "$RDF" | xmlstarlet sel -t -v '/rdf:RDF/admssw:SoftwarePackage[@rdf:about="'"$RFD_DSC_PACKAGE"'"]/schema:downloadUrl/@rdf:resource'
}

source_pkg()
{
    local PKG="$1"
    local PKG_INFO
    local SOURCE

    PKG_INFO="$(wget -q -O- "${PTS_URL}?package=${PKG}&architecture=amd64&suite=${SUITE_NAME}&annotate=yes")"
    SOURCE="$(grep -m 1 '^Source: ' <<<"$PKG_INFO" | cut -d " " -f 2)"

    if [ -z "$PKG_INFO" ]; then
        # No package info, must be a binary one
        echo "$PKG"
    elif [ -z "$SOURCE" ]; then
        # No "Source:", source's name is the same
        grep -m 1 "^Package: " <<<"$PKG_INFO" | cut -d " " -f 2
    else
        # This is the source's name
        echo "$SOURCE"
    fi
}

qa_dsc_url()
{
    local PKG="$1"
    local SOURCE
    local SOURCE_PKG_INFO
    local PFILENAME

    SOURCE="$(source_pkg "$PKG")"
    SOURCE_PKG_INFO="$(wget -q -O- "${PTS_URL}?package=${SOURCE}&architecture=amd64&suite=${SUITE_NAME}&annotate=yes")"
    PFILENAME="$(grep -m 1 '^Filename: ' <<<"$SOURCE_PKG_INFO" | cut -d " " -f 2)"

    if [ -z "$PFILENAME" ]; then
        echo "no dsc in PTS" 1>&2
        return 1
    else
        echo "${REPO}/${PFILENAME%_amd64.deb}.dsc"
    fi
}

# parse packages.debian.org
hack_url "$1"

# RDF version
dsc_url "$1"

# PTS version
qa_dsc_url "$1"
