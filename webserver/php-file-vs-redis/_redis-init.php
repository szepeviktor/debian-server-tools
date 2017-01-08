<?php

// dd if=/dev/urandom of=.pagecache bs=1M count=1

define( 'PAGE_CACHE_FILE', '.pagecache' );
$content = file_get_contents( PAGE_CACHE_FILE );

define( 'PAGE_CACHE_KEY', 'test:page_cache' );

$redis = new Redis();
$redis->connect( '127.0.0.1', 6379 );
$redis->set( PAGE_CACHE_KEY, $content );
