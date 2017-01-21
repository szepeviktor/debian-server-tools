#!/bin/bash
#
# Report changed WordPress website files.
#

declare -r DOCUMENT_ROOT="${HOME}/website/html/"

set -e

{

    # Core
    cd "$DOCUMENT_ROOT"
    nice /usr/local/bin/wp --no-debug --quiet core verify-checksums 2>&1 \
        || echo "ERROR: '$(/usr/local/bin/wp --no-debug option get blogname)' Core files"

    # Theme
    THEME="$(/usr/local/bin/wp --no-debug --quiet eval 'echo get_template_directory();')"
    cd "$THEME"
    nice git status --short 2>&1 || echo "ERROR: '${THEME}' Theme files"

    # Site (excludes core and theme)
    cd "$DOCUMENT_ROOT"
    nice git status --short 2>&1 || echo "ERROR: Site files"

} | sed -e "1s|^.|[${LOGNAME}] Website has been changed.\n&|" 1>&2
