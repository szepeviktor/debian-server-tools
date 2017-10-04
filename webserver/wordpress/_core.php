<?php

// Remove X-Mailer header from emails
add_action( 'phpmailer_init', function ( $phpmailer ) {
    $phpmailer->XMailer = ' ';
} );
