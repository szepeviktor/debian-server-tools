<?php

// Enable Jetpack Search only.
add_filter(
    'jetpack_get_available_modules',
    static function ($modules) {
        return array_intersect_key($modules, ['search' => true]);
    },
    10,
    1
);

// Disable Jetpack Backup cron job.
add_action(
    'wp_loaded',
    static function () {
        remove_all_actions('jetpack_backup_cleanup_helper_scripts');
    },
    100,
    0
);
