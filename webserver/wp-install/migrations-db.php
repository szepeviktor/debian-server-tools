<?php
/**
 * Doctrine Migrations Configuration
 *
 * @link https://www.doctrine-project.org/projects/doctrine-migrations/en/latest/reference/configuration.html
 */

require_once __DIR__ . '/vendor/autoload.php';

// Load the WordPress library.
require_once __DIR__ . '/path/to/wp-load.php';

// Set up connection.
return array(
    'driver'   => 'mysqli',
    'host'     => DB_HOST,
    'dbname'   => DB_NAME,
    'user'     => DB_USER,
    'password' => DB_PASSWORD,
);

// Configure in ./migrations.yml
// @link https://www.doctrine-project.org/projects/doctrine-migrations/en/latest/reference/configuration.html
