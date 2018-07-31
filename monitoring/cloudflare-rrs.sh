#!/bin/bash
#
# Create, read, update and delete Cloudflare DNS resource record sets.
#
# VERSION       :0.1.0
# DOCS          :https://api.cloudflare.com/
# DEPENDS       :apt-get install curl jq
# LOCATION      :/usr/local/bin/cloudflare-rrs.sh

# Usage
# Get your Global API Key https://dash.cloudflare.com/profile
#     mkdir ~/.cloudflare
#     touch ~/.cloudflare/auth-{email,key}; chmod 0600 ~/.cloudflare/auth-{email,key}
# Add HOSTED_ZONE_ID=ZONE-ID to your ~/.profile
#     cloudflare-rrs.sh . TXT
#     cloudflare-rrs.sh non-existent-to-create.example.com. AAAA
#     cloudflare-rrs.sh example.com. A
#     cloudflare-rrs.sh _acme-challenge.example.com. IN TXT
# List all zones
#     cloudflare-rrs.sh . .
# Delete a record by setting its value to ""

ZONE_ID="$HOSTED_ZONE_ID"
# @TODO X-Auth-User-Service-Key
AUTH_EMAIL_FILE="${HOME}/.cloudflare/auth-email"
AUTH_KEY_FILE="${HOME}/.cloudflare/auth-key"

Cloudflare_api()
{
    local METHOD="$1"
    local URI="$2"
    shift 2

    curl --silent -X "$METHOD" \
        -H "X-Auth-Email: ${AUTH_EMAIL}" \
        -H "X-Auth-Key: ${AUTH_KEY}" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/${URI}" "$@"
}

Get_record_identifiers()
{
    local JQ_FILTER

    printf -v JQ_FILTER '.result[] | select(.type == "%s" and .name == "%s") | .id' "$TYPE" "$NAME"
    Cloudflare_api GET "zones/${ZONE_ID}/dns_records?per_page=100" \
        | jq -r "$JQ_FILTER"
}

Validate_request()
{
    test -s "$TEMP_JSON"
    python <<EOF
import sys, json
j = open('${TEMP_JSON}').read()
try:
    json.loads(j)
except ValueError:
    sys.exit(20)
EOF
}

Usage()
{
    cat <<EOF
Usage: $0 name. TYPE
Update RRs by editing JSON data.
EOF
    exit 0
}

set -e

# Credentials
if [ ! -r "$AUTH_EMAIL_FILE" ] || [ ! -r "$AUTH_KEY_FILE" ]; then
    echo "Unconfigured ~/.cloudflare/auth-{email,key}" 1>&2
    exit 125
fi

AUTH_EMAIL="$(head -n 1 "$AUTH_EMAIL_FILE")"
AUTH_KEY="$(head -n 1 "$AUTH_KEY_FILE")"

if [ -z "$AUTH_EMAIL" ] || [ -z "$AUTH_KEY" ]; then
    echo "Missing configuration data ~/.cloudflare/auth-{email,key}" 1>&2
    exit 125
fi

NAME="$1"
# Support bind format
if [ "$2" == IN ]; then
    shift
fi
TYPE="$2"

# List all zones
if [ "$NAME" == . ] && [ "$TYPE" == . ]; then
    Cloudflare_api GET "zones?status=active&page=1&per_page=100&order=status&direction=desc&match=all" \
        | jq -r '.result[] | "\(.name)\t\(.id)"'
    exit 0
fi

# Get name. and TYPE
if [ $# -ne 2 ] || [ "${NAME:(-1)}" != . ] || [ -n "${TYPE//[A-Z]/}" ]; then
    Usage
fi

# List names and values of RRs
if [ "$NAME" == . ]; then
    printf -v JQ_LIST '[ .result[] | select(.type == "%s") | {"\(.name)": "\(.content)"} ]' "$TYPE"
    Cloudflare_api GET "zones/${ZONE_ID}/dns_records?per_page=100" | jq -r "$JQ_LIST"
    exit 0
fi

ZONE_DOMAIN="$(Cloudflare_api GET "zones/${ZONE_ID}" | jq -r '.result.name')"
if [ -z "$ZONE_DOMAIN" ]; then
    echo "Unable to retrieve zone details." 1>&2
    exit 10
fi
# Convert for usage at Cloudflare
NAME="${NAME%.}"
if [ "${NAME%$ZONE_DOMAIN}" == "$NAME" ]; then
    echo "Specify NAME with the zone domain name." 1>&2
    exit 11
fi

# Temporary file to edit JSON data
TEMP_JSON="$(mktemp)"
trap 'rm -f "$TEMP_JSON"' EXIT HUP INT QUIT PIPE TERM

# Get record IDs
RECORD_IDS="$(Get_record_identifiers)"
MX_PRIO=""

# Check response
if [ -z "$RECORD_IDS" ]; then
    # New RRs
    if [ "$TYPE" == MX ]; then
        printf -v MX_PRIO ',\n "priority":10'
    fi
    printf '{\n "name": "%s",\n "type": "%s",\n "content": "",\n "ttl": 86400,\n "proxied":false%s\n}\n' "$NAME" "$TYPE" "$MX_PRIO" \
        > "$TEMP_JSON"
    # Edit RRs
    editor "$TEMP_JSON"
    Validate_request
    # Create RRs
    RESPONSE="$(Cloudflare_api POST "zones/${ZONE_ID}/dns_records" --data "$(cat "$TEMP_JSON")")" #"
else
    # Change RRs
    if [ "$TYPE" == MX ]; then
        printf -v MX_PRIO ', priority: .priority'
    fi
    printf -v JQ_UPDATE '.result | {name: .name, type: .type, content: .content, ttl: .ttl, proxied: .proxied%s}' "$MX_PRIO"

    while read -r RECORD_ID; do
        Cloudflare_api GET "zones/${ZONE_ID}/dns_records/${RECORD_ID}?per_page=100" \
            | jq "$JQ_UPDATE" \
            > "$TEMP_JSON"
        # Edit RRs
        editor "$TEMP_JSON"
        Validate_request
        if jq '.content' < "$TEMP_JSON" | grep -q -F -x '""'; then
            # Delete RRs
            RESPONSE="$(Cloudflare_api DELETE "zones/${ZONE_ID}/dns_records/${RECORD_IDS}")"
        else
            # Update RRs
            RESPONSE="$(Cloudflare_api PUT "zones/${ZONE_ID}/dns_records/${RECORD_IDS}" --data "$(cat "$TEMP_JSON")")" #"
        fi
    done <<< "$RECORD_IDS"
fi

# Check response
grep -q -F '"success":true,' <<< "$RESPONSE"

echo "OK."
