<?php

// Reset default REST Site Health capability.
array_map(static function ($check) {
    add_filter(
        'site_health_test_rest_capability_' . $check,
        static function () {
            return 'view_site_health_checks';
        },
        PHP_INT_MAX,
        0
    );
}, [
    'background_updates',
    'loopback_requests',
    'https_status',
    'dotorg_communication',
    'authorization_header',
    'debug_enabled',
]);

// Revoke capability to access Site Health.
add_filter(
    'user_has_cap',
    static function ($capabilities) {
        return array_merge($capabilities, ['view_site_health_checks' => false]);
    },
    PHP_INT_MAX,
    1
);

// No-op WP_Site_Health class.
class WP_Site_Health
{
    public function __construct() {}
    public static function get_instance() {}
}
