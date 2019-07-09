<?php
/**
 * Use Laravel logging to communicate with the Firewall.
 *
 * Usage: Log::channel('firewall')->error('Malicious traffic detected: laravel_' . $eventSlug, $contextArray);
 */

return [
    'channels' => [

        'firewall' => [
            'driver' => 'monolog',
            'handler' => Monolog\Handler\ErrorLogHandler::class,
            'level' => 'error',
            'formatter' => Monolog\Formatter\LineFormatter::class,
            'formatter_with' => [
                'format' => '%message% %context%',
            ],
        ],

    ]
];
