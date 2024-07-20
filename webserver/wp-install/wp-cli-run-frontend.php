<?php

/**
 * Run WordPress front-end with WP-CLI.
 *
 * wp --url="https://example.com/" eval-file wp-cli-run-frontend.php
 */

WP_CLI::get_runner()->load_wordpress();

// EDIT Optionally add your code here
add_filter(
    'woocommerce_admin_features',
    static function ($features) {
        var_dump($features);
        return $features;
    },
    0,
    1
);

wp();
define('WP_USE_THEMES', true);
require_once ABSPATH . WPINC . '/template-loader.php';
