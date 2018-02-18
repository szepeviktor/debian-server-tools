<?php

$servers['imap'] = array(
    'disabled' => false,
    'name' => 'szepenet',
    'hostspec' => 'localhost',
    'hordeauth' => 'full',
    'protocol' => 'imap',
    'port' => 143,
    'secure' => false,
    'maildomain' => 'szepe.net',
    'cache' => 'hashtable',
    'quota' => array(
        'driver' => 'imap',
        'params' => array(
            'hide_when_unlimited' => true,
            'unit' => 'MB',
        ),
    ),
    // 'debug' => '/home/horde/website/log/horde-debug.log',
    'spam' => array(
         'innocent' => array(
             'display' => true,
             // Revoke and also unlearn
             'program' => '/usr/bin/spamc --reporttype=revoke --max-size=1048576',
         ),
         'spam' => array(
             'display' => false,
             // Report and also learn
             'program' => '/usr/bin/spamc --reporttype=report --max-size=1048576',
         ),
    ),
);
