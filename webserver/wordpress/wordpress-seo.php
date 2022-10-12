<?php

// Remove JSON for Linking Data
// https://json-ld.org/
// https://developers.google.com/search/docs/guides/intro-structured-data
add_filter( 'wpseo_json_ld_output', '__return_empty_array', 10, 0 );

// Dequeue HelpScout Beacon JavaScript
add_action( 'admin_enqueue_scripts', function () {
    wp_dequeue_script( 'yoast-seo-help-scout-beacon' );
}, 99, 0 );

// Hide Premium Upsell metabox and dim sidebar
add_action( 'admin_enqueue_scripts', function ( $hook ) {
    if ( false === strpos( $hook, 'wpseo_' ) ) {
        return;
    }
    $style = '.wp-admin .yoast_premium_upsell { display:none !important; }';
    $style .= '.wp-admin #sidebar-container { opacity: 0.30; }';
    wp_add_inline_style( 'wp-admin', $style );
}, 20, 1 );

// Remove Premium page
add_filter( 'wpseo_submenu_pages', function ( $submenu_pages ) {
    foreach ( $submenu_pages as $key => $submenu_page ) {
        // Fifth element is $page_slug
        if ( in_array( $submenu_page[4], ['wpseo_licenses', 'wpseo_workouts', 'wpseo_redirects'] ) ) {
            unset( $submenu_pages[ $key ] );
        }
    }
    return $submenu_pages;
}, 99, 1 );
