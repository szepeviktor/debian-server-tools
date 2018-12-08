<?php

/**
 * Unity theme
 */

$unity_theme_update = <<<'EOF'
#!/bin/bash

CURRENT="$(dirname "$0")/external-plugin-update.log"

# From wp-content/themes/unity/inc/frontend.php
EXTERNAL_PLUGINS=(
    http://www.wpopal.com/thememods/appthemer-crowdfunding.zip
    http://www.wpopal.com/thememods/js_composer.zip
    http://www.wpopal.com/thememods/revslider.zip
)

for PLUGIN in ${EXTERNAL_PLUGINS[@]}; do
    wget -q --spider -S "$PLUGIN" 2>&1 | grep -F 'Last-Modified:'
done | diff "$CURRENT" -

#exit 0

EOF;

file_put_contents( 'unity-plugin-update.sh', $unity_theme_update );
chmod( 'unity-plugin-update.sh', 0755 );
