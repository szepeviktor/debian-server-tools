<?php

$servers['gmail'] = array(
    'disabled' => false,
    'name' => 'Gmail',
    'hostspec' => 'imap.gmail.com',
    // 'hordeauth' => 'full',
    'hordeauth' => false,
    'protocol' => 'imap',
    'port' => 993,
    'secure' => 'ssl',
    'xoauth2_token' => 'EDIT-------------',
    'cache' => 'hashtable',
    'quota' => array(
        'driver' => 'imap',
        'params' => array(
            'hide_when_unlimited' => true,
            'unit' => 'MB',
        ),
    ),
    'smtp' => array(
        'auth' => true,
        // 'hordeauth' => 'full',
        'hordeauth' => false,
        'host' => 'smtp.gmail.com',
        'port' => 465,
        'secure' => 'ssl',
        'xoauth2_token' => 'EDIT---------------',
    ),
);
