<?php

// Disable post-by-email.
add_filter( 'enable_post_by_email_configuration', '__return_false', PHP_INT_MAX, 0 );
