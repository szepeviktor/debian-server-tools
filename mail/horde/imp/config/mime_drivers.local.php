<?php

// Inline HTML
$mime_drivers['html'] = array(
    'inline' => true,
    'handles' => array(
        'text/html'
    ),
    'icons' => array(
        'default' => 'html.png'
    ),
    'limit_inline_size' => 1048576,
    'phishing_check' => true
);

// Virus alert
$mime_drivers['zip'] = array(
    'handles' => array(
        'application/x-compressed',
        'application/x-zip-compressed',
        'application/zip'
    ),
    'icons' => array(
        // 'default' => 'compressed.png'
        'default' => 'virus.png' // 49px × 20px
    )
);
