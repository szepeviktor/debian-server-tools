<?php

// Disable Easy Social Share Buttons plugin updates
add_action( 'plugins_loaded', function () {
    global $essb_manager;
    if ( method_exists( $essb_manager, 'disableUpdater' ) ) {
        $essb_manager->disableUpdates( true );
    }
}, 10, 0 );
