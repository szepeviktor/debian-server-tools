<?php

	function jetpack_get_headers() {
		$ip_related_headers = array(
			'GD_PHP_HANDLER',
			'HTTP_AKAMAI_ORIGIN_HOP',
			'HTTP_CF_CONNECTING_IP',
			'HTTP_CLIENT_IP',
			'HTTP_FASTLY_CLIENT_IP',
			'HTTP_FORWARDED',
			'HTTP_FORWARDED_FOR',
			'HTTP_INCAP_CLIENT_IP',
			'HTTP_TRUE_CLIENT_IP',
			'HTTP_X_CLIENTIP',
			'HTTP_X_CLUSTER_CLIENT_IP',
			'HTTP_X_FORWARDED',
			'HTTP_X_FORWARDED_FOR',
			'HTTP_X_IP_TRAIL',
			'HTTP_X_REAL_IP',
			'HTTP_X_VARNISH',
			'REMOTE_ADDR'
		);

		foreach( $ip_related_headers as $header) {
			if ( isset( $_SERVER[ $header ] ) ) {
				$output[ $header ] = $_SERVER[ $header ];
			}
		}

		return $output;
	}

	function jetpack_protect_api( $action = 'check_ip', $request = array() ) {

// php wp-protect-api.php 1.2.3.4
global $argv; $ip = $argv[4];

		$wp_version = '4.3.1';

//		$api_key = get_site_option( 'jetpack_protect_key' );
		$api_key = '7a2e6f9b9ea3fd5c5a772e732c919cff5fd2fc12';

		$user_agent = "WordPress/{$wp_version}";

		$request['action']            = $action;
		$request['ip']                = $ip;
		$request['host']              = 'protex.herokuapp.com';
//		$request['headers']           = json_encode( jetpack_get_headers() );
		$request['headers']           = json_encode( array("REMOTE_ADDR" => $ip) );
		$request['jetpack_version']   = '3.7.2';
		$request['wordpress_version'] = strval( $wp_version );
		$request['api_key']           = $api_key;
		$request['multisite']         = "0";

		$args = array(
			'body'        => $request,
			'user-agent'  => $user_agent,
			'httpversion' => '1.0',
			'timeout'     => 15
		);

		$response_json           = wp_remote_post( 'https://api.bruteprotect.com/', $args );

var_dump( $response_json["body"] );
}

jetpack_protect_api();
