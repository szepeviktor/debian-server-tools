<?php

// Prevent activation of themes having a child theme available
add_action( 'after_switch_theme', function ( $oldtheme_name, $old_theme ) {
    $error_message = 'Reverted to previous theme as new one has a child theme';

    // Child themes are OK
    if ( is_child_theme() ) {
        return;
    }

    // Detect child theme
    $current_theme = wp_get_theme();
    $themes        = wp_get_themes();
    foreach ( $themes as $theme ) {
        // "Theme Name:" header
        if ( $current_theme->name !== $theme->parent_theme ) {
            continue;
        }

        // Switch back to the previous theme as this one has a child
        switch_theme( $old_theme->stylesheet );
        error_log( sprintf( '%s has a child theme, reverting to %s', $current_theme->name, $old_theme->name ) );
        add_action( 'admin_notices', function () {
            printf( '<div class="notice-error"><p>%s</p></div>', esc_html( $error_message ) );
        } );
        break;
    }
}, 10, 2 );
