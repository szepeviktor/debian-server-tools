<?php

// Disable Gravity Forms plugin updates
define( 'GRAVITY_MANAGER_URL', null );
define( 'GRAVITY_MANAGER_PROXY_URL', null );
add_filter( 'pre_transient_gform_update_info', '__return_true' );

// Disable auto update
// Old solution: add_filter( 'option_gform_enable_background_updates', '__return_false' );
define( 'GFORM_DISABLE_AUTO_UPDATE', true );

// Prevent continuous .htaccess file creation in wp-content/uploads/gravity_form/
add_filter( 'gform_upload_root_htaccess_rules', '__return_empty_string' );

// Multipart emails
// https://docs.gravityforms.com/gform_notification/#4-change-the-message-format
add_filter( 'gform_notification', function ( $notification ) {
    $notification['message_format'] = 'multipart';
    return $notification;
} );

// Add charset attribute to Content-Type headers in multipart messages
add_filter( 'gform_pre_send_email', function ( $email, $message_format ) {
    if ( 'multipart' === $message_format ) {
        $charset = sprintf( ' charset="%s";', get_option( 'blog_charset' ) );
        // '\S+' could be preg_quote( GFCommon::$email_boundary )
        $email['message'] = preg_replace(
            '/^(--\S+\r?\nContent-Type: text\/(plain|html);)(\r?\n)/m',
            '\1' . $charset . '\3',
            $email['message']
        );
    }
    return $email;
}, 10, 2 );

// Hide admin tooltips
add_filter( 'gform_tooltips', '__return_empty_array' );

// Make honeypot the second field
add_filter( 'gform_pre_render', function ( $form ) {
    if ( count( $form['fields'] ) > 1
        && 'honeypot' === RGFormsModel::get_input_type( end( $form['fields'] ) )
        && 'honeypot' !== RGFormsModel::get_input_type( $form['fields'][1] )
    ) {
        $honeypot = end( $form['fields'] );
        array_pop( $form['fields'] );
        array_splice( $form['fields'], 1, 0, array( $honeypot ) );
    }
    return $form;
} );
