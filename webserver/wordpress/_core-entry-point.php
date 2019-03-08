<?php // phpcs:disable WordPress.Files.FileName.NotHyphenatedLowercase
/**
 * Helper functions to determine entry point.
 *
 * @package          Coreentrypoint
 * @author           Viktor Szépe <viktor@szepe.net>
 * @link             https://github.com/szepeviktor/wordpress-plugin-construction
 * @wordpress-plugin
 * Plugin Name: Helper functions to determine entry point. (MU)
 * Version: 0.1.0
 * License: The MIT License (MIT)
 * Author: Viktor Szépe
 */

/**
 * Already existing functions.
 *
 * - doing_ajax()
 * - is_trackback()
 * - is_admin()
 */

// By API.
function is_installing() {
	return ( defined( 'WP_INSTALLING' ) && WP_INSTALLING );
}
function is_cron() {
	return ( defined( 'DOING_CRON' ) && DOING_CRON );
}
function is_wp_cli() {
	return ( defined( 'WP_CLI' ) && WP_CLI );
}
function is_xml_rpc() {
	return ( defined( 'XMLRPC_REQUEST' ) && XMLRPC_REQUEST );
}
function is_async_upload() {
	return ( isset( $_SERVER['SCRIPT_FILENAME'] ) && ABSPATH . 'wp-admin/async-upload.php' === $_SERVER['SCRIPT_FILENAME'] );
}
function is_rest() {
	return ( defined( 'REST_REQUEST' ) && REST_REQUEST );
}

// By user authentication.
function is_anonymous_users() {
	return ! is_user_logged_in();
}
function current_user_can_frontend( $capability ) {
	return ( ! is_admin() && current_user_can( $capability ) );
}
function current_user_cannot_frontend( $capability ) {
	return ( ! is_admin() && ! current_user_can( $capability ) );
}
function current_user_can_admin( $capability ) {
	return ( is_admin() && current_user_can( $capability ) );
}
function current_user_cannot_admin( $capability ) {
	return ( is_admin() && ! current_user_can( $capability ) );
}
