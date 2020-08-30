<?php

namespace App\Config;

use Illuminate\Config\Repository;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Log;

/**
 * Add to App\ProvidersAppServiceProvider::register()
 *
 *     $this->app->extend('config', function ($config) {
 *         return new RepositoryWithLogging($config->all());
 *     });
 */
class RepositoryWithLogging extends Repository
{
    /**
     * Get the specified configuration value.
     *
     * @param  array|string  $key
     * @param  mixed  $default
     * @return mixed
     */
    public function get($key, $default = null)
    {
        if (is_array($key)) {
            return $this->getMany($key);
        }

        if (!$this->has($key)) {
            Log::notice('Missing configuration key: ' . $key);
        }
        return Arr::get($this->items, $key, $default);
    }

    /**
     * Get many configuration values.
     *
     * @param  array  $keys
     * @return array
     */
    public function getMany($keys)
    {
        $config = [];

        foreach ($keys as $key => $default) {
            if (is_numeric($key)) {
                [$key, $default] = [$default, null];
            }

            if (!$this->has($key)) {
                Log::notice('Missing configuration key: ' . $key);
            }
            $config[$key] = Arr::get($this->items, $key, $default);
        }

        return $config;
    }
}
