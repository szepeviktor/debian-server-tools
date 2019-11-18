<?php

// Disable TGMPA (procedural)
add_action( 'after_setup_theme', function () {
    remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
    // EDIT
    remove_action( 'tgmpa_register', 'CUSTOM-FUNCTION' );
}, PHP_INT_MAX, 0 );


// Disable TGMPA (OOP)
add_action( 'after_setup_theme', function () {
    // EDIT - example: $wpoEngine
    global $wpoEngine;
    if ( method_exists( $wpoEngine, 'initRequiredPlugin' ) ) {
        remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
        remove_action( 'tgmpa_register', array( $wpoEngine, 'initRequiredPlugin' ) );
    }
}, PHP_INT_MAX, 0 );
