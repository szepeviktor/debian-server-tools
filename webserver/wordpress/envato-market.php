<?php

/**
 * Envato Market plugin for ThemeForest updates
 *
 * wp plugin install https://envato.github.io/wp-envato-market/dist/envato-market.zip --activate
 */

$envato_market_update = <<<'EOF'
#!/bin/bash

WP_CONTENT_DIR="$(wp --no-debug eval 'echo WP_CONTENT_DIR;')"

if [ -n "$WP_CONTENT_DIR" ] && [ -d "$WP_CONTENT_DIR" ]; then
    wp --no-debug plugin install "https://github.com/envato/wp-envato-market/archive/master.zip" --force
fi

EOF;

file_put_contents( 'envato-market-update.sh', $envato_market_update );
chmod( 'envato-market-update.sh', 0755 );
