#!/bin/bash
#
# Check domain expiry.
#
# VERSION       :0.1.10
# DATE          :2018-11-29
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install s-nail
# LOCATION      :/usr/local/bin/domain-expiry.sh
# CRON-WEEKLY   :/usr/local/bin/domain-expiry.sh
# CONFIG        :/etc/domainexpiryrc

# Configuration example
#
#     # Expiry dates should be in UTC.
#     DOMAIN_EXPIRY_ALERT_DATE="2 weeks"
#     DOMAIN_EXPIRY=(
#         DOMAIN:EXPIRY-DATE
#         example.co.uk:2016-07-18
#         "has-a-space.com:April 10, 2016"
#         escaped.com:April\ 10,\ 2016
#     )

In_domain_expiry()
{
    local STRING="$1"

    for ITEM in "${DOMAIN_EXPIRY[@]}"; do
        if [ "${ITEM%%:*}" == "$STRING" ]; then
            return 0
        fi
    done

    return 1
}

# Prepare the list for finding second-level domains
Publicsuffix_regexp()
{
    local LIST_URL="https://publicsuffix.org/list/public_suffix_list.dat"

    # Download list,
    #   remove empty lines and comments,
    #   escape dots, asterisks and add SLD regexp
    wget -q -O- "$LIST_URL" \
        | grep -v '^\s*$\|^\s*//' \
        | sed -e 's/\./\\./g' -e 's/\*/.*/' -e 's/^\(.*\)$/[^.]\\+\\.\1$/'
}

Apache_domains()
{
    apache2ctl -S | sed -n -e 's/^.* \(namevhost\|alias\) \(\S\+\).*$/\2/p'
}

Courier_domains()
{
    (
        cd /etc/courier/
        # Gather all domains,
        #   remove alias destinations and user part of email addresses,
        #   remove non-domains (local users)
        grep -v -h '^\s*[#;]\|^\s*$' me defaultdomain locals hosteddomains esmtpacceptmailfor.dir/* aliases/* \
            | sed -e 's/:.*$//' -e 's/^.*@//' \
            | grep -v '^[^.]\+$'
    )
}

Server_domain()
{
    hostname -f
}

DAEMON="domain-expiry"
DOMAIN_EXPIRY_RC="/etc/domainexpiryrc"
DOMAIN_EXPIRY_ALERT_DATE="2 weeks"
declare -a DOMAIN_EXPIRY
declare -i ALERT_SEC
declare -i EXPIRY_SEC

set -e

logger -t "$DAEMON" "Domain expiry started"

# shellcheck disable=SC1090
source "$DOMAIN_EXPIRY_RC"

# We need a file for `grep -f -`
DOMAIN_LIST="$(mktemp)"

# Find all domains used
{
    Apache_domains
    Courier_domains
    Server_domain

    # Deduplicate
} | sort -u >"$DOMAIN_LIST"

# Find valid SLD-s, deduplicate again
DOMAINS="$(Publicsuffix_regexp | grep -o -f - "$DOMAIN_LIST" | sort -u)"

rm "$DOMAIN_LIST"

# Do we have expiry date for all of our domains?
while read -r DOMAIN; do
    if ! In_domain_expiry "$DOMAIN"; then
        echo "Domain ${DOMAIN} is missing from configuration file." 1>&2
    fi
done <<<"$DOMAINS"

# Check expiry
ALERT_SEC="$(date --date="$DOMAIN_EXPIRY_ALERT_DATE" "+%s")"
for ITEM in "${DOMAIN_EXPIRY[@]}"; do
    DOMAIN="${ITEM%%:*}"
    EXPIRY="${ITEM#*:}"

    if ! EXPIRY_SEC="$(date --date="$EXPIRY" "+%s")" || [ -z "$EXPIRY_SEC" ] || [ -n "${EXPIRY_SEC//[0-9]/}" ]; then
        echo "Domain ${DOMAIN} has invalid expiry date (${EXPIRY})" 1>&2
        continue
    fi

    if [ "$EXPIRY_SEC" -lt "$ALERT_SEC" ]; then
        echo "Domain ${DOMAIN} is about to expire at ${EXPIRY}"

        # Print links
        if [ "$DOMAIN" != "${DOMAIN%.hu}" ]; then
            # .hu
            printf 'https://info.domain.hu/webwhois/hu/domain/%s\n\n' "${DOMAIN%.hu}"
        elif [ "$DOMAIN" != "${DOMAIN%.eu}" ]; then
            # .eu
            printf 'https://whois.eurid.eu/en/?domain=%s\nhttp://whois.domaintools.com/%s\n\n' "$DOMAIN" "$DOMAIN"
        else
            # Other TLD-s
            printf 'https://www.whois.com/whois/%s\nhttp://whois.domaintools.com/%s\n\n' "$DOMAIN" "$DOMAIN"
        fi
    fi
done | s-nail -E -S "hostname=" -S from="${DAEMON} <root>" -s "domain expiry alert" root

exit 0
