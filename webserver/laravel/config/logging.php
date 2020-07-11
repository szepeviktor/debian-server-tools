<?php
/**
 * Use Laravel logging to communicate with the Firewall.
 *
 * Usage: Log::channel('firewall')->error('Malicious traffic detected: laravel_' . $eventSlug, $contextArray);
 */

use Monolog\Formatter\LineFormatter;
use Monolog\Handler\ErrorLogHandler;

return [
    'channels' => [

        'firewall' => [
            'driver' => 'monolog',
            'handler' => ErrorLogHandler::class,
            'level' => 'error',
            'formatter' => LineFormatter::class,
            'formatter_with' => [
                'format' => '%message% %context%',
            ],
        ],

    ]
];
