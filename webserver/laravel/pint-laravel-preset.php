<?php

namespace App\Factories
{
    class ConfigurationFactory
    {
        public static function preset(array $array): array
        {
            return $array;
        }
    }
}

namespace
{
    $pintPresetUrl = 'https://github.com/laravel/pint/raw/main/resources/presets/laravel.php';
    $pintLocalCache = '.php-cs-fixer.laravel.cache';
    if (! is_file($pintLocalCache)) {
        copy($pintPresetUrl, $pintLocalCache);
        // @TODO Replace App\Factories -> SzepeViktor\PhpCsFixer
    }

    return require $pintLocalCache;
}
