#!/bin/bash
#
# Extract arguments from an SPF record recursively.
#
# VERSION       :0.1.1
# DATE          :2018-04-16
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://www.openspf.org/SPF_Record_Syntax
# LOCATION      :/usr/local/bin/spf-survey.sh

Do_spf()
{
    local DOMAIN="$1"
    local SPF_RECORD
    local MECHANISM

    SPF_RECORD="$(host -t TXT "$DOMAIN" | sed -n -e 's|.* descriptive text "\(v=spf1 .*\)"$|\1|p')" #'

    while read -r -d " " MECHANISM; do
        case "$MECHANISM" in
            "v=spf1")
                continue
                ;;
            "ip4:"*)
                echo "${MECHANISM#ip4:}"
                ;;
            "ip6:"*)
                echo ":${MECHANISM#ip6:}"
                ;;
            "include:"*)
                # Recurse into include
                Do_spf "${MECHANISM#include:}"
                ;;
            #"a"|"mx"|"ptr")
            #    # TODO
            #    # Get records
            #    # Resolve IP addresses, handle CNAMEs
            #    Do_spf IPs
            #    ;;
            "?all"|"~all"|"-all")
                # "?" Neutral, "~" SoftFail, "-" Fail
                continue
                ;;
            *)
                echo "Unknown mechanism in SPF: ${MECHANISM}" 1>&2
                exit 100
                ;;
        esac
    done <<<"$SPF_RECORD"
}

set -e

Do_spf "$1"
