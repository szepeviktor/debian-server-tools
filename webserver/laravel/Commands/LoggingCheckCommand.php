<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

class LoggingCheckCommand extends Command
{
    public const LOGGER_NAME = 'stack';

    public const CHANNEL_NAMES = ['bugsnag', 'daily', 'stack'];

    /**
     * @var string
     */
    protected $signature = 'project:check-logging';

    /**
     * @var string
     */
    protected $description = 'Check logging configuration';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle(): int
    {
        // Instantiate logger
        Log::channel();

        if (Log::getDefaultDriver() !== self::LOGGER_NAME) {
            $this->error('Incorrect log driver!');

            return Command::FAILURE;
        }

        if ((new Collection(Log::getChannels()))->keys()->sort()->diff(self::CHANNEL_NAMES)->isNotEmpty()) {
            $this->error('Incorrect log channels!');

            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }
}
