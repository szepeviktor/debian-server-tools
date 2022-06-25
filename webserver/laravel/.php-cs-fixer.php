<?php

$finder = PhpCsFixer\Finder::create()
    ->in([
        __DIR__ . '/app',
        __DIR__ . '/config',
        __DIR__ . '/database',
        __DIR__ . '/routes',
        __DIR__ . '/tests',
    ])
;

$config = new PhpCsFixer\Config();
return $config->setRules(require __DIR__ . '/pint-laravel-preset.php')
    ->setFinder($finder)
;

// Start command: vendor/bin/php-cs-fixer fix --allow-risky=yes --dry-run
