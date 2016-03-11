<?php

// https://codex.wordpress.org/Editing_wp-config.php

/** Shared hosting */

// User home directory, absolute path without trailing slash
if ( empty( $_SERVER['HOME'] ) ) {
    define( '_HOME_DIR', realpath( getenv( 'HOME' ) ) );
} else {
    define( '_HOME_DIR', realpath( $_SERVER['HOME'] ) );
}

// Different FTP/PHP UID
define( 'FS_METHOD', 'direct' );
define( 'FS_CHMOD_DIR', ( 0775 & ~ umask() ) );
define( 'FS_CHMOD_FILE', ( 0664 & ~ umask() ) );

// Upload temp and session directory
ini_set( 'upload_tmp_dir', _HOME_DIR . '/tmp' );
ini_set( 'session.save_path', _HOME_DIR . '/session' );

// Create dirs - Comment out after first use!
mkdir( _HOME_DIR . '/tmp', 0700 );
mkdir( _HOME_DIR . '/session', 0700 );

// See: shared-hosting-aid/enable-logging.php
ini_set( 'error_log', _HOME_DIR . '/log/error.log' );
ini_set( 'log_errors', 1 );

/** Security */

// WordPress fail2ban
//define( 'O1_BAD_REQUEST_ALLOW_CONNECTION_CLOSE', true );
//define( 'O1_BAD_REQUEST_CDN_HEADERS', 'HTTP_X_AMZ_CF_ID:HTTP_VIA:HTTP_X_FORWARDED_FOR' );
//require_once dirname( __FILE__ ) . '/wp-miniban-htaccess.inc.php';
require_once dirname( __FILE__ ) . '/wp-fail2ban-bad-request-instant.inc.php';

/** Core */

// See: wp-config-live-debugger/
define( 'WP_DEBUG', false );

// wp-content locataion
define( 'WP_CONTENT_DIR', '/HOME/WP-ROOT-DIR/static' );
define( 'WP_CONTENT_URL', 'http://DOMAIN.URL/static' );
//define( 'WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/static' );
//define( 'WP_CONTENT_URL', sprintf( '%s%s/static',
//    ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) ? 'https://' : 'http://', $_SERVER['SERVER_NAME'] ) );

// Moving to subdirs
//     siteurl += /site , search-and-replace: /wp-includes/ -> /site/wp-includes/ , /wp-content/ -> /static/

//define( 'WP_MEMORY_LIMIT', '96M' );
//define( 'WP_MAX_MEMORY_LIMIT', '384M' );
define( 'DISALLOW_FILE_EDIT', true );
define( 'WP_USE_EXT_MYSQL', false );
define( 'WP_POST_REVISIONS', 10 );

//define( 'WP_CACHE', true );

// CLI cron see: debian-server-tools:/webserver/wp-cron-cli.sh
// HTTP cron see: shared-hosting-aid/wp-cron-http.sh
// Simple CLI cron job: /usr/bin/php ABSPATH/wp-cron.php # stdout and stderr to cron email
define( 'DISABLE_WP_CRON', true );
define( 'AUTOMATIC_UPDATER_DISABLED', true );

/** Plugins */

//define( 'WP_CACHE_KEY_SALT', 'COMPANY-SHORT_' );
//define( 'PODS_SESSION_AUTO_START', false );
//define( 'WPCF7_LOAD_CSS', false );
//define( 'WPCF7_LOAD_JS', false );
//define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );
define( 'ENABLE_FORCE_CHECK_UPDATE', true );
//define( 'ITSEC_FILE_CHECK_CRON', true );
//define( 'ITSEC_BACKUP_CRON', true );

/** DB */

define( 'DB_NAME', 'database_name_here' );
define( 'DB_USER', 'username_here' );
define( 'DB_PASSWORD', 'password_here' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
$table_prefix  = 'wp_';

/** Salts */

//      wget -qO- https://api.wordpress.org/secret-key/1.1/salt/


/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    // Change ABSPATH if wp-config is outside WordPress root
    //define( 'ABSPATH', dirname( __FILE__ ) . '/site/' );
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
