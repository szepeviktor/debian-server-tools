#!/bin/bash
#
# Report changed Drupal website files.
#

# It is an hourly cron job.

declare -r CURRENT_CORE_HASH="00000000000000000000000000000000"

declare -r DOCUMENT_ROOT="${HOME}/website/code/"

Tripwire_fake() {
    # Display checksum of Drupal in hash/drupal
    #find "$(dirname "$DOCUMENT_ROOT")/hash/drupal" -type f | xargs cat | nice md5sum; exit

    # Core
    CORE_HASH="$(find "$(dirname "$DOCUMENT_ROOT")/hash/drupal" -type f -printf './%P\0' | xargs -0 cat | md5sum)"
    test "$CORE_HASH" == "${CURRENT_CORE_HASH}  -" \
        || echo "ERROR: '$(/usr/local/bin/drush core-status --fields=uri --field-labels=0|head -n1)' Core files"

    # Theme
    #THEME="$(/usr/local/bin/drush php-eval 'echo DRUPAL_ROOT . "/" . path_to_theme();')"
    #(
    #    cd "$THEME"
    #    nice git status --short 2>&1 || echo "ERROR: '${THEME}' Theme files"
    #)

    # Site content (excludes core and theme)
    nice git status --short 2>&1 || echo "ERROR: Site files"
}

set -e

cd "$DOCUMENT_ROOT"
Tripwire_fake | sed -e "1s|^.|[${LOGNAME}] Website has changed.\\n&|" 1>&2
