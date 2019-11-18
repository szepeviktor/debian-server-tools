<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class IsDownForMaintenance extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'isdown';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Determine if the application is currently down';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return int Exit status.
     */
    public function handle()
    {
        if (!$this->laravel->isDownForMaintenance()) {
            $this->info('Application is up.');
            return 0;
        }

        $data = json_decode(file_get_contents(storage_path('framework/down')), true);

        $status = sprintf(
            "Time: %s\nRetry: %d\nMessage: '%s'",
            date('c', $data['time']),
            $data['retry'] ?: 0,
            $data['message']
        );
        $this->line($status);
        return 10;
    }
}
