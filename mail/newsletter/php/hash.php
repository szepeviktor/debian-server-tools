<?php

require_once __DIR__ . '/PseudoCrypt.php';

$id = hexdec(hash('crc32b', 'AM:' . $argv[1]));
$cr = \PseudoCrypt\PseudoCrypt::hash($id, 6);

echo $cr;
