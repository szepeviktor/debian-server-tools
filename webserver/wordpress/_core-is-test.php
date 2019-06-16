<?php

/**
 * Return detection results of all HTTP request types.
 *
 * @return string
 */
function is_request_test() {
    $tests = [
        'installing',
        'index',
        'frontend',
        'admin',
        'async-upload',
        'preview',
        'autosave',
        'rest',
        'ajax',
        'xmlrpc',
        'trackback',
        'search',
        'feed',
        'robots',
        'cron',
        'wp-cli',
    ];
    $results = [];
    foreach ( $tests as $name ) {
        $results[] = sprintf(
            '%s%s',
            Is::request( $name ) ? '' : '!',
            $name
        );
    }
    return implode( ',', $results );
}
