#!/bin/bash
#
# Check domain expiry.
#
# VERSION       :0.1.3
# DATE          :2015-08-06
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install heirloom-mailx
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
#         escaped.com:April 10,\ 2016
#     )

DAEMON="domain-expiry"
DOMAIN_EXPIRY_RC="/etc/domainexpiryrc"
DOMAIN_EXPIRY_ALERT_DATE="2 weeks"
DOMAIN_EXPIRY=( )
source "$DOMAIN_EXPIRY_RC"

In_domain_expiry() {
    local STRING="$1"

    for ITEM in "${DOMAIN_EXPIRY[@]}"; do
        [ "${ITEM%%:*}" == "$STRING" ] && return 0
    done

    return 1
}

# Prepare the list for finding second-level domains
Publicsuffix_regexp() {
    local LIST_URL="https://publicsuffix.org/list/public_suffix_list.dat"

    # Download list,
    #   remove empty lines and comments,
    #   escape dots, asterisks and add SLD regexp
    wget -qO- "$LIST_URL" \
        | grep -v "^\s*$\|^\s*//" \
        | sed -e 's/\./\\./g' -e 's/\*/.*/' -e 's/^\(.*\)$/[^.]\\+\\.\1$/'
}

Apache_domains() {
    apache2ctl -S \
        | sed -n 's;^.* \(namevhost\|alias\) \(\S\+\).*$;\2;p'
}

Courier_domains() {
    pushd /etc/courier/ > /dev/null

    # Gather all domains,
    #   remove alias destinations and user part of email addresses,
    #   remove non-domains (local users)
    grep -v -h "^\s*[#;]\|^\s*$" me defaultdomain locals hosteddomains esmtpacceptmailfor.dir/* aliases/* \
        | sed -e 's/:.*$//' -e 's/^.*@//' \
        | grep -v "^[^.]\+$"

    popd > /dev/null
}

Server_domain() {
    hostname -f
}

logger -t "$DAEMON" "Domain expiry started"

# We need a file for `grep -f -`
DOMAIN_LIST="$(tempfile)"
ALERT_SEC="$(date --date="$DOMAIN_EXPIRY_ALERT_DATE" "+%s")"

# Find all domains used
{
    Apache_domains
    Courier_domains
    Server_domain

  # Deduplicate
} | sort | uniq > "$DOMAIN_LIST"

# Find valid SLD-s,
#   deduplicate again
DOMAINS="$(Publicsuffix_regexp | grep -o -f - "$DOMAIN_LIST" \
    | sort | uniq)"

rm "$DOMAIN_LIST"

# Do we have expiry date for all of our domains?
while read DOMAIN; do
    if ! In_domain_expiry "$DOMAIN"; then
        echo "Domain ${DOMAIN} is missing from configuration file." >&2
    fi
done <<< "$DOMAINS"

# Check expiry
for ITEM in "${DOMAIN_EXPIRY[@]}"; do
    DOMAIN="${ITEM%%:*}"
    EXPIRY="${ITEM#*:}"
    EXPIRY_SEC="$(date --date="$EXPIRY" "+%s")"

    if [ $? != 0 ] || [ -z "$EXPIRY_SEC" ] || [ -n "${EXPIRY_SEC//[0-9]/}" ]; then
        echo "Domain ${DOMAIN} has invalid expiry date (${EXPIRY})" >&2
        continue
    fi

    if [ "$EXPIRY_SEC" -lt "$ALERT_SEC" ]; then
        echo "Domain ${DOMAIN} is about to expire at ${EXPIRY}."
        printf "\nhttp://www.domain.hu/domain/domainsearch/?tld=hu&domain=%s\nhttp://bgp.he.net/dns/%s#_whois\nhttp://whois.domaintools.com/%s\n" \
            "${DOMAIN%.hu}" "$DOMAIN" "$DOMAIN"
    fi
done | mailx -E -S from="${DAEMON} <root>" -s "[ad.min] Domain expiry alert" root

exit 0
