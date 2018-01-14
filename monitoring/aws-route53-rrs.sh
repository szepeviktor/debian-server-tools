#!/bin/bash
#
# Create, list and update AWS Route53 DNS resource record sets.
#
# VERSION       :0.1.2
# DOCS          :http://jmespath.org/examples.html
# DEPENDS       :pip install awscli
# LOCATION      :/usr/local/bin/aws-route53-rrs.sh

# Usage
#     Add HOSTED_ZONE_ID=HOSTED-ZONE-ID to your ~/.profile
#     aws-route53-edit-rrs.sh . TXT
#     aws-route53-edit-rrs.sh non-existent-to-create.example.com. AAAA
#     aws-route53-edit-rrs.sh example.com. A
#     aws-route53-edit-rrs.sh example.com. IN TXT

HOSTED_ZONE="$HOSTED_ZONE_ID"

Route53_list_rrs() {
    aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" "$@"
}

Route53_change_rrs() {
    local TEMP_JSON="$1"

    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE" \
        --change-batch "file://${TEMP_JSON}"
}

Usage() {
    cat <<EOF
Usage: $0 name. TYPE
Update RRs by editing JSON data.
EOF
    exit 0
}

set -e

NAME="$1"
# Support bind format
if [ "$2" == "IN" ]; then
    shift
fi
TYPE="$2"

# Get name. and TYPE
if [ $# != 2 ] || [ "${NAME:(-1)}" != . ] || [ -n "${TYPE//[A-Z]/}" ]; then
    Usage
fi

# List names of RRs
if [ "$NAME" == . ]; then
    Route53_list_rrs --query "ResourceRecordSets[?Type == '${TYPE}'].Name"
    exit 0
fi

# Temporary file to edit JSON data
TEMP_JSON="$(mktemp)"
trap 'rm -f "$TEMP_JSON"' EXIT HUP INT QUIT PIPE TERM

# Get RRs
Route53_list_rrs --query \
    "ResourceRecordSets[?Name == '${NAME}'] | [?Type == '${TYPE}'] | [0]" \
    > "$TEMP_JSON"
# Check response
if [ "$(cat "$TEMP_JSON")" == null ]; then
    # New RRs
    printf '{
    "Name": "%s",
    "Type": "%s",
    "ResourceRecords": [
        {
            "Value": ""
        }
    ],
    "TTL": 86400
}
' "$NAME" "$TYPE" > "$TEMP_JSON"
fi

# Edit RRs
editor "$TEMP_JSON"

# Build the request
# @FIXME Ugly hack: the same file is input and output at the same time
# @TODO Delete RRs by changing action to "Action": "DELETE",
printf '{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet":
%s
        }
    ]
}' "$(cat "$TEMP_JSON")" > "$TEMP_JSON"

# Validate request
python <<EOF
import sys, json
j = open('${TEMP_JSON}').read()
try:
    json.loads(j)
except ValueError:
    sys.exit(1)
EOF

# Update RRs
RESPONSE="$(Route53_change_rrs "$TEMP_JSON")"
# Check response
grep -q '"ChangeInfo": {' <<< "$RESPONSE"
grep -q '"Status": "PENDING"' <<< "$RESPONSE"

echo "OK."
