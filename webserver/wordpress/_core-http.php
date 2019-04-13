<?php
/**
 * Use these constants to restrict outbound HTTP requests.
 *
 * define( 'WP_HTTP_BLOCK_EXTERNAL', true );
 * define( 'WP_ACCESSIBLE_HOSTS', 'api.wordpress.org' );
 */

// Log failed external HTTP requests.
add_action( 'http_api_debug', function ( $response, $context, $class, $r, $url ) {
	if ( 'response' !== $context || 'Requests' !== $class || ! is_wp_error( $response ) ) {
		return;
	}
	error_log(
		sprintf(
			'%s [%s] %s (%s)',
			'WordPress external HTTP request failed with message',
			$response->get_error_code(),
			$url,
			json_encode( $r, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE )
		)
	);
}, 99, 5 );

// Debug external HTTP requests.
if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) :
	add_action( 'http_api_debug', function ( $response, $context, $class, $r, $url ) {
		if ( 'response' !== $context || 'Requests' !== $class || is_wp_error( $response ) ) {
			return;
		}
		error_log(
			sprintf(
				'%s: %s (%s)',
				'WordPress external HTTP request',
				$url,
				json_encode( $r, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE )
			)
		);
	}, 100, 5 );
endif;
