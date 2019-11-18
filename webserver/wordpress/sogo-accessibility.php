<?php

// Disable SOGO Accessability plugin (a11y) license check
add_action( 'wp_ajax_check_license', function () {
    add_filter( 'pre_http_request', function ( $status ) {
        return new WP_Error( 'sogo_license_check_disabled' );
    }, 10, 1 );
}, 10, 0 );
