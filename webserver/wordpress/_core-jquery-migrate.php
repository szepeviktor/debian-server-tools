<?php

// Never enqueue jQuery Migrate before WordPress 5.5
add_action( 'wp_default_scripts', function ( $scripts ) {
    if ( is_admin() || empty( $scripts->registered['jquery'] ) ) {
        return;
    }
    $scripts->registered['jquery']->deps = array_diff(
        $scripts->registered['jquery']->deps,
        ['jquery-migrate']
    );
}, 10, 1);
