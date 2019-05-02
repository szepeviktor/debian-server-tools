#!/bin/bash
#
# Generate ACF Pro stubs of functions only.
#

PLUGIN_VERSION="5.7.8"

Fix_phpdoc()
{
    # - Fix type and variable name order for @param
    # - Remove remaining parentheses for @param
    # - Fix type and variable name order for @return
    # - Remove remaining parentheses for @return
    # - Fix "void"
    find ./includes/ ./pro/ -type f -name "*.php" -exec sed \
        -e 's#^\(\s*\*\s*@param\s\+\)\(\$\S\+\)\s\+(\(\S\+\))\(.*\)$#\1\3 \2\4#' \
        -e 's#^\(\s*\*\s*@param\s\+\)(\(\S\+\))\(.*\)$#\1\2\3#' \
        -e 's#^\(\s*\*\s*@return\s\+\)\(\$\S\+\)\s\+(\(\S\+\))\(.*\)$#\1\3 \2\4#' \
        -e 's#^\(\s*\*\s*@return\s\+\)(\(\S\+\))\(.*\)$#\1\2\3#' \
        -e 's#n/a#void#i' \
        -i "{}" ";"
}

# Check plugin
if ! grep -q 'Plugin Name:\s\+Advanced Custom Fields PRO' ./acf.php 2>/dev/null; then
    echo "Please extract ACF PRO into the current directory!" 1>&2
    echo "https://www.advancedcustomfields.com/pro/" 1>&2
    exit 10
fi

Fix_phpdoc

# Generate stubs
if [ ! -x vendor/bin/generate-stubs ]; then
    composer require --no-interaction --update-no-dev --prefer-dist giacocorsiglia/stubs-generator
fi
vendor/bin/generate-stubs --functions --out=acf-pro-stubs-${PLUGIN_VERSION}.php ./includes/ ./pro/
