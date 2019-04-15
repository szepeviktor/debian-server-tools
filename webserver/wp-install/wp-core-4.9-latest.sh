#!/bin/bash
#
# Show the latest 4.9 core version.
#

# WordPress.org API
wget -q -O- "https://api.wordpress.org/core/version-check/1.7/" \
    | jq -r '.offers[] | select(.version | startswith("4.9.")) | .version'

# Composer package
#composer show -a johnpbloch/wordpress "^4.9"
