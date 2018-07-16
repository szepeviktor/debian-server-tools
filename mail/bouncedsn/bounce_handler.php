<?php

// Add the following to PHP FPM pool configuration.
//     php_admin_flag[mail.add_x_header] = Off

require __DIR__ . '/vendor/autoload.php';
new Bouncedsn\Bouncedsn();
