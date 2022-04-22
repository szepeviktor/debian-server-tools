<?php

// Remove global styles.
add_action(
    'wp',
    static function () {
        remove_action('wp_enqueue_scripts', 'wp_enqueue_global_styles');
        remove_action('wp_footer', 'wp_enqueue_global_styles', 1);
        remove_action('wp_body_open', 'wp_global_styles_render_svg_filters');
        // TODO: Is this part of one of the hooks above?
        // remove_filter('render_block', 'wp_render_duotone_support', 10, 2);
    },
    100,
    0
);
