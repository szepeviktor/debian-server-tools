<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class IsDownForMaintenanceCommand extends Command
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
     * Execute the console command.
     *
     * @return int Exit status.
     */
    public function handle()
    {
        if (!$this->laravel->isDownForMaintenance()) {
            $this->info('Application is up.');

            return Command::FAILURE;
        }

        $data = json_decode(file_get_contents(storage_path('framework/down')), true);

        $this->info('Number of data fields: ' . (string) count($data));

        return Command::SUCCESS;
    }
}
