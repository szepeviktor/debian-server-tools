<?php

// Add the following to PHP FPM pool configuration.
//     php_admin_flag[mail.add_x_header] = Off
//     env[BOUNCE_DSN_LOG] = "/path/to/sparkpost.log"

require __DIR__ . '/vendor/autoload.php';

// Supported providers:   sparkpost, amazonses, mailjet
new Bouncedsn\Bouncedsn( 'sparkpost', 'postmaster@example.com', 'mailer-daemon@example.com' );
