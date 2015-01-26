#!/bin/bash
#
# Loop through sitemap and preload cache by scraping the site.
# There is 1 second delay between requests.

SITEMAP="<SITE-URL>/sitemap.xml"
ACCEPT_LANGUAGES="hu"
#ACCEPT_LANGUAGES="hu,en-us;q=0.7,en;q=0.3"

WGET_VERSION="$(wget -V | sed -n 's|.*Wget \([0-9.]\+\) .*|\1|p')"
USER_AGENT="Mozilla/5.0 (compatible; preload-cache/${WGET_VERSION}; +https://github.com/szepeviktor/debian-server-tools)"

# 1s delay, user agent, language, compression, HTTP HEAD requests
wget -q -O- "$SITEMAP" \
    | sed -n 's|^.*<loc>\([^<]\+\)</loc>.*$|\1|gp' \
    | wget -q --spider --wait 1 \
        --user-agent="$USER_AGENT" --header="Accept-Language: ${ACCEPT_LANGUAGES}" --header="Accept-Encoding: gzip" -i -
