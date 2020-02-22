<?php

// Fix PHP bug #50921: '200 OK' HTTP status despite PHP error
// https://bugs.php.net/bug.php?id=50921
add_action(
    'shutdown',
    function () {
        // display_errors needs to be disabled
        if ( '1' === ini_get( 'display_errors' ) ) {
            return;
        }
        $error = error_get_last();
        if ( E_ERROR === $error['type'] ) {
            header( 'HTTP/1.1 500 Internal Server Error' );
        }
    },
    0,
    0
);
