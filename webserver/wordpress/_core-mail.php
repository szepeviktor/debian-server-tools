<?php

// Remove X-Mailer header from emails.
add_action( 'phpmailer_init', function ( $phpmailer ) {
    $phpmailer->XMailer = ' ';
}, 10, 1 );

// Log mail sending errors.
add_action( 'wp_mail_failed', function ( $error ) {
    if ( ! is_wp_error( $error ) ) {
        error_log( 'WordPress core failure: not an instance of WP_Error in "wp_mail_failed"' );
        return;
    }
    $message = sprintf(
        'Mail sending error: [%s] %s',
        $error->get_error_code(),
        $error->get_error_message()
    );
    error_log( $message );
    openlog( 'php-fpm', LOG_PID, LOG_LOCAL0 );
    syslog( LOG_ALERT, $message );
}, -1, 1 );
