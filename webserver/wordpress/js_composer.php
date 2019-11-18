<?php

// Disable WPBakery Visual Composer plugin updates
add_action( 'plugins_loaded', function () {
    global $vc_manager;
    if ( method_exists( $vc_manager, 'disableUpdater' ) ) {
        $vc_manager->disableUpdater( true );
        add_filter( 'pre_option_wpb_js_js_composer_purchase_code', '__return_true' );
    }
}, 10, 0 );
