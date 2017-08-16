<?php

$servers['imap'] = array(
    'disabled' => false,
    'name' => 'szepenet',
    'hostspec' => 'localhost',
    'hordeauth' => 'full',
    'protocol' => 'imap',
    'port' => 143,
    'secure' => 'false',
    'quota' => array(
        'driver' => 'imap',
        'params' => array(
            'hide_when_unlimited' => true,
            'unit' => 'MB',
        ),
    ),
);
