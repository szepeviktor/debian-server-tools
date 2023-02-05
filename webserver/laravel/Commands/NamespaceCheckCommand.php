<?php

namespace App\Console\Commands;

use FilesystemIterator;
use Illuminate\Console\Command;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;

class NamespaceCheckCommand extends Command
{
    /**
     * The console command name.
     *
     * @var string
     */
    protected $name = 'namespace:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check namespace of all classes';

    /**
     * Namespace-classfile path map.
     */
    protected array $map;

    /**
     * Execute the console command.
     *
     * @return int Exit status.
     */
    public function handle()
    {
        $this->map = include dirname(__DIR__, 3) . '/vendor/composer/autoload_classmap.php';

        $missing = array_merge(
            $this->testDirectory(dirname(__DIR__, 3) . '/app'),
            $this->testDirectory(dirname(__DIR__, 3) . '/tests')
        );

        if (count($missing) !== 0) {
            foreach ($missing as $pathname) {
                $this->error('Not found: ' . $pathname);
            }

            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    /**
     * @return string|false
     */
    protected function getClassName(string $path): string|bool
    {
        return array_search($path, $this->map, true);
    }

    protected function testDirectory(string $path): array
    {
        $missing = [];
        $testsIterator = new RecursiveDirectoryIterator(
            $path,
            FilesystemIterator::SKIP_DOTS | FilesystemIterator::CURRENT_AS_FILEINFO
        );
        foreach(new RecursiveIteratorIterator($testsIterator) as $file) {
            $className = $this->getClassName($file->getPathname());

            if ($className === false) {
                $missing[] = $file->getPathname();
                continue;
            }

            $this->info('OK: ' . $className);
        }

        return $missing;
    }
}
