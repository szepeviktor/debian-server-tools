#!/bin/bash
#
# Loop through sitemap and preload cache by scraping the site.
# There is 1 second delay between requests.
#
# VERSION       :0.3
# DATE          :2015-04-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/preload-cache.sh

# SITEMAP="<SITE-URL>/sitemap.xml"
SITEMAP_URL="$1"
# ACCEPT_LANGUAGES="hu,en-us;q=0.7,en;q=0.3"
ACCEPT_LANGUAGES="$2"

[ -z "$ACCEPT_LANGUAGES" ] && ACCEPT_LANGUAGES="hu"

WGET_VER="$(wget -V | sed -n 's|.*Wget \([0-9.]\+\) .*|\1|p')"
USER_AGENT="Mozilla/5.0 (compatible; preload-cache/${WGET_VER}; +https://github.com/szepeviktor/debian-server-tools)"

# HTTP HEAD requests without retries
wget -q --user-agent="$USER_AGENT" -O- "$SITEMAP_URL" \
    | sed -n 's|^.*<loc>\([^<]\+\)</loc>.*$|\1|gp' \
    | wget --quiet --wait 1 --tries 1 --spider \
        --user-agent="$USER_AGENT" --header="Accept-Language: ${ACCEPT_LANGUAGES}" --header="Accept-Encoding: gzip" \
        -i -
