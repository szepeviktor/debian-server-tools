<?php

// Remove sender domain error.
add_action(
    'wpcf7_config_validator_validate',
    static function ($configValidator) {
        $configValidator->remove_error('mail.sender', WPCF7_ConfigValidator::error_email_not_in_site_domain);
    },
    10,
    1
);
