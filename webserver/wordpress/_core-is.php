<?php // phpcs:disable WordPress.Files.FileName.NotHyphenatedLowercase
/**
 * Helper functions to determine entry point.
 *
 * @package          WordPressIs
 * @author           Viktor Szépe <viktor@szepe.net>
 * @link             https://github.com/szepeviktor/wordpress-plugin-construction
 *
 * @wordpress-plugin
 * Plugin Name: Helper functions to determine entry point. (MU)
 * Version:     0.1.1
 * License:     The MIT License (MIT)
 * Author:      Viktor Szépe
 */

/**
 * Various Is::xxx() helpers.
 */
class Is {

	/**
	 * Whether given user is an administrator.
	 *
	 * @param \WP_User $user The given user.
	 * @return bool
	 */
	public static function admin( \WP_User $user ): bool {
		return is_multisite() ? user_can( $user, 'manage_network' ) : user_can( $user, 'manage_options' );
	}

	/**
	 * Whether the current user is not logged in.
	 *
	 * @return bool
	 */
	public static function anonymous_users(): bool {
		return ( ! is_user_logged_in() );
	}

	/**
	 * Whether the current user is a comment author.
	 *
	 * @return bool
	 */
	public static function comment_author(): bool {
		return isset( $_COOKIE[ 'comment_author_' . COOKIEHASH ] );
	}

	/**
	 * Whether current webserver interface is CLI.
	 *
	 * @return bool
	 */
	public static function cli(): bool {
		return ( 'cli' === php_sapi_name() );
	}

	/**
	 * Whether current request is of the given type.
	 *
	 * @param string $type Type of request.
	 * @return bool
	 */
	public static function request( string $type ): bool {
		switch ( $type ) {
			case 'installing':
				return ( defined( 'WP_INSTALLING' ) && WP_INSTALLING );
			case 'index':
				return ( defined( 'WP_USE_THEMES' ) && WP_USE_THEMES );
			case 'frontend':
				return ( ( ! is_admin() || wp_doing_ajax() ) && ! wp_doing_cron() );
			case 'admin':
				return is_admin();
			case 'async-upload':
				return ( isset( $_SERVER['SCRIPT_FILENAME'] ) && ABSPATH . 'wp-admin/async-upload.php' === $_SERVER['SCRIPT_FILENAME'] );
			case 'preview':
				return is_preview();
			case 'rest':
				return ( defined( 'REST_REQUEST' ) && REST_REQUEST );
			case 'ajax':
				return wp_doing_ajax();
			case 'xmlrpc':
				return ( defined( 'XMLRPC_REQUEST' ) && XMLRPC_REQUEST );
			case 'trackback':
				return is_trackback();
			case 'search':
				return is_search();
			case 'feed':
				return is_feed();
			case 'robots':
				return is_robots();
			case 'cron':
				return wp_doing_cron();
			case 'wp-cli':
				return ( defined( 'WP_CLI' ) && WP_CLI );
			default:
				_doing_it_wrong( __METHOD__, esc_html( sprintf( 'Unknown request type: %s', $type ) ), '0.1.0' );
				return false;
		}
	}
}
