<?php

add_action( 'wp_footer', function () {
    echo "\n<!-- Infrastructure, source code management and consulting: Viktor Szépe <viktor@szepe.net> -->\n";
}, PHP_INT_MAX, 0 );
