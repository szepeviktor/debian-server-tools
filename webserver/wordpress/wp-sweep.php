<?php

// Polylang's excluded taxonomies for WP-Sweep
add_filter( 'wp_sweep_excluded_taxonomies', function( $excluded_taxonomies ) {
    $excluded_taxonomies[] = 'language';
    $excluded_taxonomies[] = 'post_translations';

    return $excluded_taxonomies;
} );
