#!/bin/bash
#
# Retrieve the .dsc file in three ways.
#
# VERSION       :0.1
# DATE          :2014-08-01
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install xmlstarlet


SUITE="testing"
SUITE_NAME="jessie"
REPO="http://http.debian.net/debian"

hack_url() {
    local PKG="$1"
    local DSCURL="$(wget -qO- "https://packages.debian.org/${SUITE}/${PKG}" | grep -o 'http.*\.dsc">\[' | cut -d'"' -f1)"

    if [ -z "$DSCURL" ]; then
        echo "no .dsc" >&2
        return 1
    else
        echo "$DSCURL"
    fi
}

rdf_url() {
    # only source packages
    local PKG="$1"
    local DIRLEN="1"
    [ "${PGK:0:3}" = lib ] && DIRLEN="4"

    wget -qO- "http://packages.qa.debian.org/${PKG:0:DIRLEN}/${PKG}.html" \
        | grep -o "http://packages\.qa\.debian\.org/.*/.*\.rdf"
}

dsc_url() {
    local RDF="$(rdf_url "$1" | wget -qO- -i-)"
    [ -z "$RDF" ] && return 1

    # find testing
    local RDF_TESTING_VAL="http://www.debian.org/releases/${SUITE}#distribution"
    local RDF_TESTING_ASSET="$(echo "$RDF" | xmlstarlet sel -t -v 'rdf:RDF/rdf:Description[@rdf:about="'"$RDF_TESTING_VAL"'"]/admssw:includedAsset/@rdf:resource')"

    # find testing's dsc
    local RFD_DSC_PACKAGE="$(echo "$RDF" | xmlstarlet sel -t -v '/rdf:RDF/admssw:SoftwareRelease[@rdf:about="'"$RDF_TESTING_ASSET"'"]/admssw:package/@rdf:resource')"

    # get dsc URL
    echo "$RDF" | xmlstarlet sel -t -v '/rdf:RDF/admssw:SoftwarePackage[@rdf:about="'"$RFD_DSC_PACKAGE"'"]/schema:downloadUrl/@rdf:resource'
}

source_pkg() {
    local PKG="$1"

    local PKG_INFO="$(wget -qO- "${PTS_URL}?package=${PKG}&architecture=amd64&suite=${SUITE_NAME}&annotate=yes")"
    local SOURCE="$(grep -m1 "^Source: " <<< "$PKG_INFO" | cut -d' ' -f2)"

    # no package info, must be a binary one
    if [ -z "$PKG_INFO" ]; then
        echo "$PKG"
    # no Source:, source's name is the same
    elif [ -z "$SOURCE" ]; then
        grep -m1 "^Package: " <<< "$PKG_INFO" | cut -d' ' -f2
    else
    # this is the source's name
        echo "$SOURCE"
    fi
}

qa_dsc_url() {
    local PKG="$1"
    PTS_URL="http://qa.debian.org/cgi-bin/dcontrol"

    local SOURCE="$(source_pkg "$PKG")"
    local SOURCE_PKG_INFO="$(wget -qO- "${PTS_URL}?package=${SOURCE}&architecture=amd64&suite=${SUITE_NAME}&annotate=yes")"
    local PFILENAME="$(grep -m1 "^Filename: " <<< "$SOURCE_PKG_INFO" | cut -d' ' -f2)"

    if [ -z "$PFILENAME" ]; then
        echo "no dsc in PTS" >&2
        return 1
    else
        echo "${REPO}/${PFILENAME%_amd64.deb}.dsc"
    fi
}

#########################################################

# parse packages.debian.org
hack_url "$1"

# RDF version
dsc_url "$1"

# PTS version
qa_dsc_url "$1"

