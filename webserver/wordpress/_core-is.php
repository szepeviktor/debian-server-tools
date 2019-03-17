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
 * Version:     0.1.0
 * License:     The MIT License (MIT)
 * Author:      Viktor Szépe
 */

/**
 * Various Is::xxx() helpers.
 */
class Is {

	/**
	 * Whether given user is an administrator.
	 */
	public static function admin( \WP_User $user ): bool {
		return is_multisite() ? user_can( $user, 'manage_network' ) : user_can( $user, 'manage_options' );
	}

	/**
	 * Whether the current user is not logged in.
	 */
	public static function anonymous_users(): bool {
		return ( ! is_user_logged_in() );
	}

	/**
	 * Whether current webserver interface is CLI.
	 */
	public static function cli(): bool {
		return ( 'cli' === php_sapi_name() );
	}

	/**
	 * Whether current request is of then given type.
	 */
	public static function request( string $type ): bool {
		switch ( $type ) {
			case 'admin':
				return is_admin();
			case 'ajax':
				return wp_doing_ajax();
			case 'cron':
				return wp_doing_cron();
			case 'frontend':
				return ( ( ! is_admin() || wp_doing_ajax() ) && ! wp_doing_cron() );
			case 'rest':
				return ( defined( 'REST_REQUEST' ) && REST_REQUEST );
			case 'trackback':
				return is_trackback();
			case 'async-upload':
				return ( isset( $_SERVER['SCRIPT_FILENAME'] ) && ABSPATH . 'wp-admin/async-upload.php' === $_SERVER['SCRIPT_FILENAME'] );
			case 'xmlrpc':
				return ( defined( 'XMLRPC_REQUEST' ) && XMLRPC_REQUEST );
			case 'installing':
				return ( defined( 'WP_INSTALLING' ) && WP_INSTALLING );
			case 'wp-cli':
				return ( defined( 'WP_CLI' ) && WP_CLI );
			default:
				_doing_it_wrong( __METHOD__, esc_html( sprintf( 'Unknown request type: %s', $type ) ), '0.1.0' );
				return false;
		}
	}
}
