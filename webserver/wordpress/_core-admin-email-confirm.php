<?php

// Disable admin email confirmation.
add_filter('admin_email_check_interval', '__return_zero', PHP_INT_MAX, 0);

// Hard-code maintainer email address.
/*
add_filter(
    'pre_option_admin_email',
    static function () {
        return 'admin@szepe.net';
    },
    PHP_INT_MAX,
    0
);
add_filter(
    'pre_option_new_admin_email',
    static function () {
        return 'admin@szepe.net';
    },
    PHP_INT_MAX,
    0
);
*/
