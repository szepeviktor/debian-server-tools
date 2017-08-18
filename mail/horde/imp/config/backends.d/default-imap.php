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
    'spam' => array(
         'innocent' => array(
             'display' => true,
             // 'program' => '/usr/bin/spamc -L ham',
             // 'program' => '/usr/local/bin/multi-stdout.sh "/usr/bin/spamc -L ham" "/usr/bin/pyzor --homedir=/home/horde/.pyzor whitelist"',
             // Learn and report
             'program' => '/usr/bin/spamc -L ham -C revoke',
         ),
         'spam' => array(
             'display' => false,
             // 'program' => '/usr/bin/spamc -L spam',
             // 'program' => '/usr/local/bin/multi-stdout.sh "/usr/bin/spamc -L spam" "/usr/bin/pyzor --homedir=/home/horde/.pyzor report"',
             // Learn and report
             'program' => '/usr/bin/spamc -L spam -C report',
         ),
    ),
);
