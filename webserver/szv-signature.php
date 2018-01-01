<?php

add_action( 'wp_footer', function () {
    echo "\n<!-- Infrastructure, source code management and support: Viktor Szépe <viktor@szepe.net> -->\n";
}, 9999 );
