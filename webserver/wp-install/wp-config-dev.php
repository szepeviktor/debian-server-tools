<?php

// See also: wp-config-live-debug.php

/*
PHP-FPM pool config
    env[WP_ENV] = development
Apache mod_php .htaccess
    SetEnv WP_ENV development
Values: production, staging, development
*/

// WP_ENV by roots.io  https://github.com/roots/wp-stage-switcher/blob/master/wp-stage-switcher.php
define( 'WP_ENV', ( getenv( 'WP_ENV' ) ? : 'development' ) );

/** Development environment */
if ( 'development' === WP_ENV ) {
    // WP_LOCAL_DEV by Mark Jaquith  https://gist.github.com/markjaquith/1044546
    define( 'WP_LOCAL_DEV', true );

    // WARNING! Lazy dev site - Some links and images are still pointing to the production site. Use WP-CLI search-replace.
    define( '_REQUEST_SCHEME', ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) ? 'https://' : 'http://' );
    // EDIT core directory
    define( 'WP_SITEURL', sprintf( '%s%s/wordpress', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_HOME', _REQUEST_SCHEME . $_SERVER['HTTP_HOST'] );
    // EDIT wp-content directory (WP_CONTENT_DIR is absolute)
    define( 'WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/static' );
    // EDIT wp-content directory
    define( 'WP_CONTENT_URL', sprintf( '%s%s/static', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_DEBUG', true );
    define( 'WP_CACHE', false );
    /*
    // Lazy dev content filter in a MU plugin: /wp-content/mu-plugins/lazy-dev-filter.php
    <?php
    add_filter( 'the_content', function ( $content ) {
        // EDIT core production URL
        $production_home = 'https://production.tld';
        $local_content = str_replace( $production_home, 'http://localhost', $content );
        // Add more replacements here!
        return $local_content;
    }, 20 );
    */
}
// EDIT production domain name
if ( 'production.tld' === $_SERVER['HTTP_HOST'] || 'production' === WP_ENV ) {
    exit( 'Environment failure: use production configuration!' );
}

/** Constants from production environment */
define( 'WP_USE_EXT_MYSQL', false );
define( 'WP_POST_REVISIONS', 10 );
define( 'DISABLE_WP_CRON', true );
define( 'AUTOMATIC_UPDATER_DISABLED', true );

// See /webserver/WP-config-dev.md for complete how-to
