#!/bin/bash
#
# Create, list and update Godaddy DNS resource record sets.
#
# VERSION       :0.1.2
# DOCS          :https://developer.godaddy.com/doc
# KEYS          :https://developer.godaddy.com/keys/
# DEPENDS       :apt-get install curl python
# LOCATION      :/usr/local/bin/godaddy-rrs.sh
# CONFIG        :~/.godaddy/api-key
# CONFIG        :~/.godaddy/api-secret
# CONFIG        :~/.godaddy/domain

# Usage
#     godaddy-rrs.sh . TXT
#     godaddy-rrs.sh non-existent-to-create. AAAA
#     godaddy-rrs.sh @. A
#     GODADDY_DOMAIN=other-domain.tld godaddy-rrs.sh @. IN TXT

API_BASE_URL="https://api.godaddy.com"

API_KEY_FILE="${HOME}/.godaddy/api-key"
API_SECRET_FILE="${HOME}/.godaddy/api-secret"
GODADDY_DOMAIN_FILE="${HOME}/.godaddy/domain"

Godaddy_list_rrs() {
    local PARAMETERS="$1"
    local API_URL

    printf -v API_URL "%s/v1/domains/%s/records/%s" \
        "$API_BASE_URL" "$GODADDY_DOMAIN" "${PARAMETERS//@/%40}"

    curl -s -X "GET" \
        -H "Authorization: sso-key ${API_KEY}:${API_SECRET}" \
        -H "Accept: application/json" \
        "$API_URL" \
        | Json_dump
}

Godaddy_change_rrs() {
    local TEMP_JSON="$1"
    local PARAMETERS="$2"
    local API_URL

    printf -v API_URL "%s/v1/domains/%s/records/%s" \
        "$API_BASE_URL" "$GODADDY_DOMAIN" "${PARAMETERS//@/%40}"

    curl -s -X "PUT" \
        -H "Authorization: sso-key ${API_KEY}:${API_SECRET}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --data-binary "@${TEMP_JSON}" \
        "$API_URL"
}

Json_dump() {
    local SCRIPT='
import sys, json
j = sys.stdin.read()
try:
    d = json.loads(j)
except ValueError:
    sys.exit(13)
print(json.dumps(d, indent=2))'

    # stdin is used for data input
    python -c "$SCRIPT"
}

Usage() {
    cat <<EOF
Usage: $0 NAME. TYPE
Update RRs by editing JSON data.
Specify NAME without the domain name.
EOF
    exit 1
}

set -e

if [ ! -r "$API_KEY_FILE" ] \
    || [ ! -r "$API_SECRET_FILE" ] \
    || [ ! -r "$GODADDY_DOMAIN_FILE" ]; then
    echo "Unconfigured ~/.godaddy/{api-key,api-secret,domain}" 1>&2
    exit 125
fi

API_KEY="$(head -n 1 "$API_KEY_FILE")"
API_SECRET="$(head -n 1 "$API_SECRET_FILE")"
# Allow setting domain name
if [ -z "$GODADDY_DOMAIN" ]; then
    GODADDY_DOMAIN="$(head -n 1 "$GODADDY_DOMAIN_FILE")"
fi

if [ -z "$API_KEY" ] \
    || [ -z "$API_SECRET" ] \
    || [ -z "$GODADDY_DOMAIN" ]; then
    echo "Missing configuration data ~/.godaddy/{api-key,api-secret,domain}" 1>&2
    exit 125
fi

NAME="$1"
# Support bind format
if [ "$2" == "IN" ]; then
    shift
fi
TYPE="$2"

# Check name. and type
if [ $# != 2 ] || [ "${NAME:(-1)}" != . ] || [ -n "${TYPE//[A-Z]/}" ]; then
    Usage
fi

# List RRs
if [ "$NAME" == . ]; then
    Godaddy_list_rrs "$TYPE"
    exit 0
fi

# Convert for usage at Godaddy
NAME="${NAME%.}"
if [ "${NAME%$GODADDY_DOMAIN}" != "$NAME" ]; then
    echo "Specify NAME without the domain name." 1>&2
    exit 10
fi

# Temporary file to edit JSON data
TEMP_JSON="$(mktemp)"
trap 'rm -f "$TEMP_JSON"' EXIT HUP INT QUIT PIPE TERM

# Get RRs
Godaddy_list_rrs "${TYPE}/${NAME}" > "$TEMP_JSON"
# Check response
if [ "$(cat "$TEMP_JSON")" == "[]" ]; then
    # New RRs
    if [ "$TYPE" == "MX" ]; then
        printf '[
  {
    "name": "%s",
    "type": "MX",
    "priority": 10,
    "data": "",
    "ttl": 86400
  }
]' \
            "$NAME" > "$TEMP_JSON"
    else
        printf '[
  {
    "name": "%s",
    "type": "%s",
    "data": "",
    "ttl": 86400
  }
]' \
            "$NAME" "$TYPE" > "$TEMP_JSON"
    fi
fi

# Edit RRs
editor "$TEMP_JSON"

# Validate request
python <<EOF
import sys, json
j = open('${TEMP_JSON}').read()
try:
    json.loads(j)
except ValueError:
    sys.exit(11)
EOF

# Update RRs
RESPONSE="$(Godaddy_change_rrs "$TEMP_JSON" "${TYPE}/${NAME}")"
# Check response
if [ "$RESPONSE" != "{}" ]; then
    {
        echo "ERROR: $?"
        echo "$RESPONSE" | Json_dump
        echo
    } 1>&2
    exit 12
fi

echo "OK."
