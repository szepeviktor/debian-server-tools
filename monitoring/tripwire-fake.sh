#!/bin/bash
#
# Report changed WordPress website files.
#

# It is an hourly cron job.

declare -r DOCUMENT_ROOT="${HOME}/website/code/"

Tripwire_fake() {
    # Core
    nice /usr/local/bin/wp --no-debug --quiet core verify-checksums 2>&1 \
        || echo "ERROR: '$(/usr/local/bin/wp --no-debug option get blogname)' Core files"

    # Theme (child theme)
    THEME="$(/usr/local/bin/wp --no-debug --quiet eval 'echo get_stylesheet_directory();')"
    (
        cd "$THEME"
        nice git status --short 2>&1 || echo "ERROR: '${THEME}' Theme files"
    )

    ## Parent theme
    #THEME_PARENT="$(/usr/local/bin/wp --no-debug --quiet eval 'echo get_template_directory();')"
    #(
    #    cd "$THEME_PARENT"
    #    nice git status --short 2>&1 || echo "ERROR: '${THEME_PARENT}' Parent Theme files"
    #)

    # Site content (excludes core and theme)
    # See /webserver/wordpress.gitignore
    nice git status --short 2>&1 || echo "ERROR: Site files"
}

set -e

cd "$DOCUMENT_ROOT"
Tripwire_fake | sed -e "1s|^.|[${LOGNAME}] Website has changed.\\n&|" 1>&2
