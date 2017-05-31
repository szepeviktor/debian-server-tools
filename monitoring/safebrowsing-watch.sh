#!/bin/bash
#
# One line description for this script.
#
# VERSION       :0.2.0
# DATE          :2017-05-28
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install curl
# DOCS          :https://developers.google.com/safe-browsing/v4/lookup-api#http-post-request
# DOCS          :https://developers.google.com/safe-browsing/v4/reference/rest/
# KEYS          :https://developers.google.com/safe-browsing/v4/get-started
# LOCATION      :/usr/local/bin/safebrowsing-watch.sh
# CRON-DAILY    :/usr/local/bin/safebrowsing-watch.sh
# CONFIG        :/etc/safebrowsingrc

# Configuration
#
#     API_KEY=""
#     CLIENT_ID="szepe-net-bot"
#     CLIENT_VERSION="2.0.0"
#     SB_WATCH=(
#         http://malware.testing.google.test/testing/malware/
#     )

SB_WATCH_RC="/etc/safebrowsingrc"
API_BASE_URL="https://safebrowsing.googleapis.com/v4/threatMatches:find"
declare -a SB_WATCH
declare -a URLS

Join_by() {
    local IFS="$1"

    shift

    echo "$*"
}

set -e

# shellcheck disable=SC1090
source "$SB_WATCH_RC"

if [ -z "$CLIENT_ID" ] \
    || [ -z "$CLIENT_VERSION" ] \
    || [ -z "$API_KEY" ]; then
    exit 100
fi

# API URL
printf -v API_URL "%s?key=%s" "$API_BASE_URL" "$API_KEY"

# Website URL-s
for URL in "${SB_WATCH[@]}"; do
    printf -v URL_JSON '{"url": "%s"}' "${URL// /%20}"
    URLS+=( "$URL_JSON" )
done

# Request body
TEMP_JSON="$(mktemp)"
trap 'rm -f "$TEMP_JSON"' EXIT HUP INT QUIT PIPE TERM
printf '{
  "client": {
    "clientId": "%s",
    "clientVersion": "%s"
  },
  "threatInfo": {
    "threatTypes": ["THREAT_TYPE_UNSPECIFIED", "MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
    "platformTypes": ["ANY_PLATFORM"],
    "threatEntryTypes": ["URL"],
    "threatEntries": [
      %s
    ]
  }
}' \
    "$CLIENT_ID" \
    "$CLIENT_VERSION" \
    "$(Join_by "," "${URLS[@]}")" \
    > "$TEMP_JSON"

RESPONSE="$(curl -s -X "POST" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    --data-binary "@${TEMP_JSON}" \
    "$API_URL")"

# Found malware
if [ "$RESPONSE" != "{}" ]; then
    echo "$RESPONSE"
    exit 10
fi

exit 0
