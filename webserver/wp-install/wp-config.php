<?php
/**
 * WordPress configuration skeleton.
 *
 * phpcs --standard=WordPress --exclude=Generic.WhiteSpace.DisallowSpaceIndent,Generic.Commenting.DocComment,Squiz.Commenting.InlineComment wp-config.php
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 * @package WordPress
 */

/** Shared hosting. */

// User home directory: absolute path without trailing slash.
if ( empty( $_SERVER['HOME'] ) ) {
    define( '_HOME_DIR', realpath( getenv( 'HOME' ) ) );
} else {
    define( '_HOME_DIR', realpath( $_SERVER['HOME'] ) ); // WPCS: sanitization ok.
}

// Upload-temp and session directory.
// phpcs:set WordPress.PHP.DiscouragedPHPFunctions exclude runtime_configuration
ini_set( 'upload_tmp_dir', _HOME_DIR . '/tmp' );
ini_set( 'session.save_path', _HOME_DIR . '/session' );

// Different FTP/PHP UID.
define( 'FS_CHMOD_DIR', ( 0775 & ~ umask() ) );
define( 'FS_CHMOD_FILE', ( 0664 & ~ umask() ) );

// Create dirs - Comment out after first use!
mkdir( _HOME_DIR . '/tmp', 0700 );
mkdir( _HOME_DIR . '/session', 0700 );

// See shared-hosting-aid/enable-logging.php
ini_set( 'error_log', _HOME_DIR . '/log/error.log' );
ini_set( 'log_errors', '1' );
ini_set( 'display_errors', '0' );

/** Security. */

/**
 * Download both files.
wget https://github.com/szepeviktor/waf4wordpress/raw/master/http-analyzer/waf4wordpress-http-analyzer.php
wget https://github.com/szepeviktor/waf4wordpress/raw/master/core-events/waf4wordpress-core-events.php
 */

// WAF for WordPress.
define( 'W4WP_ALLOW_CONNECTION_EMPTY', true ); // HTTP2.
define( 'W4WP_CDN_HEADERS', 'HTTP_X_AMZ_CF_ID:HTTP_VIA:HTTP_X_FORWARDED_FOR' ); // CDN.
define( 'W4WP_ALLOW_REDIRECT', true ); // Polylang with separate domains.
// require_once __DIR__ . '/wp-miniban-htaccess.inc.php';
require_once __DIR__ . '/waf4wordpress-http-analyzer.php';
new \Waf4WordPress\Http_Analyzer();

/** Composer. */

require_once dirname(__DIR__) . '/vendor/autoload.php';

/** Core. */

// See wp-config-live-debugger/
define( 'WP_DEBUG', false );
// Don't allow any other write method
define( 'FS_METHOD', 'direct' );

// "wp-content" location.
// EDIT!
define( 'WP_CONTENT_DIR', '/HOME/USER/SITE/DOC-ROOT/wp-content' );
define( 'WP_CONTENT_URL', 'https://DOMAIN.TLD/wp-content' );

/**
 * Moving to subdirs.
wp option set siteurl "$(wp option get siteurl)/site"
wp search-replace # /wp-includes/ -> /site/wp-includes/ and /wp-content/ -> /static/
wp option set home https://DOMAIN.TLD
wp option set siteurl https://DOMAIN.TLD/site
 */

define( 'WP_ALLOW_REPAIR', false );
define( 'WP_MEMORY_LIMIT', '40M' );
define( 'WP_MAX_MEMORY_LIMIT', '256M' );
define( 'DISALLOW_FILE_EDIT', true );
//define( 'DISALLOW_FILE_MODS', true );
define( 'WP_USE_EXT_MYSQL', false );
//define( 'WP_HTTP_BLOCK_EXTERNAL', true );
//define( 'WP_ACCESSIBLE_HOSTS', 'api.wordpress.org' );
// +Yoast SEO define( 'WP_ACCESSIBLE_HOSTS', 'api.wordpress.org,www.google.com,www.bing.com' );
define( 'WP_POST_REVISIONS', 20 );
define( 'MEDIA_TRASH', true );

/**
 * Full page cache.
define( 'WP_CACHE', true );
 */

// CLI cron job: /webserver/wp-install/wp-cron-cli.sh
// Simple CLI cron job: /usr/bin/php7.2 ABSPATH/wp-cron.php # stdout and stderr to cron email.
define( 'DISABLE_WP_CRON', true );
define( 'AUTOMATIC_UPDATER_DISABLED', true );

/**
 * Multisite.
 *
define( 'WP_ALLOW_MULTISITE', true );
define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', true );
$base = '/';
define( 'DOMAIN_CURRENT_SITE', 'example.com' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );
// define( 'WP_DEFAULT_THEME', 'theme-slug' );
 */

/** Plugins. */

// typisttech/wp-password-argon-two
define( 'WP_PASSWORD_ARGON_TWO_PEPPER', getenv( 'WP_PASSWORD_ARGON_TWO_PEPPER' ) );
// Tiny CDN - No trailing slash!
define( 'TINY_CDN_INCLUDES_URL', 'https://d2aaaaaaaaaaae.cloudfront.net/site/wp-includes' );
define( 'TINY_CDN_CONTENT_URL', 'https://d2aaaaaaaaaaae.cloudfront.net/wp-content' );
define( 'WP_CACHE_KEY_SALT', 'SITE-SHORT_' );
define( 'ENABLE_FORCE_CHECK_UPDATE', true );
/**
 * https://polylang.wordpress.com/documentation/documentation-for-developers/list-of-options-which-can-be-set-in-wp-config-php/
define( 'PLL_LINGOTEK_AD', false );
define( 'PLL_WPML_COMPAT', false );
define( 'WP_APCU_KEY_SALT', 'SITE-SHORT_' );
define( 'MEMCACHED_SERVERS', '127.0.0.1:11211:0' );
define( 'PODS_LIGHT', true );
define( 'PODS_SESSION_AUTO_START', false );
define( 'WPCF7_LOAD_CSS', false );
define( 'WPCF7_LOAD_JS', false );
define( 'ACF_LITE', true ); // Use 'acf/settings/show_admin' filter!
define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );
define( 'YIKES_MC_API_KEY', '00000000-us3' );
 * Non-free plugins.
define( 'GF_LICENSE_KEY', '' ); // Gravity Forms "rg_gforms_key".
define( 'OTGS_DISABLE_AUTO_UPDATES', true ); // WPML.
 */

/** Database. */

// Use /mysql/wp-createdb.sh
define( 'DB_NAME', 'database_name_here' );
define( 'DB_USER', 'username_here' );
define( 'DB_PASSWORD', 'password_here' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
$table_prefix = 'wp_'; // WPCS: override ok.

/** Salts. */

/**
 * Use WordPress.org API
wget -qO- https://api.wordpress.org/secret-key/1.1/salt/
 */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/core/' );
    // phpcs:set WordPress.PHP.DevelopmentFunctions exclude error_log
    error_log( 'Please use wp-load.php to load WordPress.' );
    exit;
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
