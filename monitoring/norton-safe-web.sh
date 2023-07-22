#!/bin/bash
#
# Check Norton Safe Web status.
#
# VERSION       :0.1.0
# DATE          :2023-03-12
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install curl xmlstarlet
# LOCATION      :/usr/local/sbin/norton-safe-web.sh

NSW_WATCH=(
    http://malware.testing.google.test/testing/malware/
)

# Website URL-s for Norton API
for URL in "${NSW_WATCH[@]}"; do
    printf -v NORTON_API_URL 'https://ratings-wrs.norton.com/brief?url=%s' "${URL// /%20}"
    RESPONSE="$(curl -s "${NORTON_API_URL}")"

    API_VERSION="$(xmlstarlet sel -t -v "//symantec/@v" <<<"${RESPONSE}")"
    SITE_ELEMENT="$(xmlstarlet ed -O -m "//symantec/site" "." -d "//symantec" -d "//site/@id" -d "//site/@cache" -d "//site/text()" <<<"${RESPONSE}")"

    # Check API version
    if [ "${API_VERSION}" != "2.5" ]; then
        echo "$RESPONSE" 1>&2
        exit 12
    fi

    # Not good site
    # COMBINED_RATING_ATTR = GOOD_SITE, SECURITY_RATING_ATTR = GOOD_SITE, BUSINESS_RATING_ATTR = UNKNOWN_SITE
    if [ "${SITE_ELEMENT}" != '<site r="g" sr="g" br="u"/>' ]; then
        echo "$RESPONSE" 1>&2
        exit 11
    fi

    sleep 5
done
