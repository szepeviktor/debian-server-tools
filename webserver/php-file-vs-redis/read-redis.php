<?php

define( 'PAGE_CACHE_KEY', 'test:page_cache' );

$redis = new Redis();
$redis->connect( '127.0.0.1', 6379 );
echo $redis->get( PAGE_CACHE_KEY );
