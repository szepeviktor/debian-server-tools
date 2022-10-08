<?php

// Enable manual installation of themes with theme/ subdirectory.
function _core_theme_subdir_helper($source)
{
    static $themePath;

    $screen = get_current_screen();
    if (!$screen instanceof \WP_Screen || $screen->id !== 'update') {
        return $source;
    }

    $action = isset($_REQUEST['action']) ? $_REQUEST['action'] : '';
    if ($action !== 'upload-theme') {
        return $source;
    }

    if (is_wp_error($source)) {
        if (
            $source->get_error_code() === 'incompatible_archive_theme_no_style'
            && isset($themePath)
            && is_dir($themePath . 'theme')
        ) {
            // Run on priority 11
            return $themePath;
        }

        return $source;
    }

    // Run on priority 0
    $themePath = $source;

    return $source;
}

add_filter(
    'upgrader_source_selection',
    '_core_theme_subdir_helper',
    0,
    1
);

add_filter(
    'upgrader_source_selection',
    '_core_theme_subdir_helper',
    11,
    1
);
