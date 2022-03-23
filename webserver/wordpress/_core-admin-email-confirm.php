<?php

// Disable admin email confirmation.
add_filter('admin_email_check_interval', '__return_zero', PHP_INT_MAX, 0);
