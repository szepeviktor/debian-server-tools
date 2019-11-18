<?php

// Remove Address Book submenu
add_action( 'admin_menu', function () {
    remove_submenu_page( 'flamingo', 'flamingo' );
}, 9, 0 );
