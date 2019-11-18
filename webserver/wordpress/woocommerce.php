<?php

// Remove WooCommerce guided tour videos
add_action( 'current_screen', function () {
    get_current_screen()->remove_help_tab( 'woocommerce_guided_tour_tab' );
}, 51, 0 );
