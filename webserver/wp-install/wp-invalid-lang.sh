#!/bin/bash
#
# Find WordPress translations not matching the core's available languages.
#
# VERSION       :0.1.2
# DEPENDS       :apt-get install wget jq

WP_ORG_CORE_TRANLATIONS="https://api.wordpress.org/translations/core/1.0/"

set -e

LANGS_REGEXP="en_US|$(wget -q -O- "$WP_ORG_CORE_TRANLATIONS" | jq -r '.translations[].language' | paste -s -d "|")"

while read -r MO; do
    MO_LANG="$(basename "$MO")"
    MO_LANG="${MO_LANG##*-}"
    MO_LANG="${MO_LANG%.mo}"
    if grep -q -x -E "$LANGS_REGEXP" <<<"$MO_LANG"; then
        continue
    fi

    echo "Unknown language code: ${MO}" 1>&2
done < <(find . -type f -name "*.mo")
