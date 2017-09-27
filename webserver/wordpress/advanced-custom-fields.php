<?php

/**
 * Add-ons
 *
 * - acf-gravityforms-add-on
 */

// Hide admin pages
add_filter( 'acf/settings/show_admin', '__return_false' );

// Export fields to .acf/acf-export.json and as code to inc/acf-fields.php
