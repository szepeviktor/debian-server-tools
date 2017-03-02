#!/bin/bash
#
# Loop through sitemap and preload page cache by scraping the site.
#
# VERSION       :0.3.0
# DATE          :2015-04-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/preload-cache.sh

# There is 1 second delay between requests.

# SITEMAP="<SITE-URL>/sitemap.xml"
SITEMAP_URL="$1"
# ACCEPT_LANGUAGES="hu,en-us;q=0.7,en;q=0.3"
ACCEPT_LANGUAGES="${2:-hu}"

set -e

WGET_VER="$(wget --version | sed -n -e 's|.*Wget \([0-9.]\+\) .*|\1|p')"
USER_AGENT="Mozilla/5.0 (compatible; preload-cache/${WGET_VER}; +https://github.com/szepeviktor/debian-server-tools)"

# HTTP HEAD requests without retries
wget --quiet --output-document=- --user-agent="$USER_AGENT" "$SITEMAP_URL" \
    | sed -n -e 's|^.*<loc>\([^<]\+\)</loc>.*$|\1|gp' \
    | wget --quiet --spider --wait 1 --tries 1 \
        --user-agent="$USER_AGENT" --header="Accept-Language: ${ACCEPT_LANGUAGES}" --header="Accept-Encoding: gzip" \
        --input-file=-
