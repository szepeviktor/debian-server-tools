<?php

// Move Activity menu under Dashboard
add_filter( 'wp_user_activity_menu_humility', '__return_true', 10, 0 );
