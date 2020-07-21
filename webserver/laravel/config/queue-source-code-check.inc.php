<?php

namespace App\Providers;

use Dotenv\Dotenv;
use Exception;
use Illuminate\Queue\Events\JobProcessing;
use Illuminate\Support\Env;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;

class AppServiceProvider extends ServiceProvider
{
    public function boot()
    {
        // Check for queue workers with outdated source code
        Queue::before(function (JobProcessing $event) {
            // Re/load .env file
            $app = app();
            Dotenv::create(
                Env::getRepository(),
                $app->environmentPath(),
                $app->environmentFile()
            )->safeLoad();

            if (Env::get('APP_HASH') !== config('projectconfig.hash')) {
                $errorMessage = 'Queue workers run with outdated source code!';
                Log::error($errorMessage);
                $event->job->fail(new Exception($errorMessage));
            }
        });
    }
}
