<?php declare(strict_types = 1);
/**
 * Convert Laravel presets from StyleCI to PHP CS Fixer.
 *
 * 1. Install PHP CS Fixer: phive install php-cs-fixer
 * 2. Add /.php_cs.cache to .gitignore
 * 3. Start: tools/php-cs-fixer fix -v --dry-run
 *
 * @see https://styleci.readme.io/docs/presets#section-laravel
 */

$fixers = (new PhpCsFixerLaravel())->getFixers();

$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/app')
;

return PhpCsFixer\Config::create()
    ->setRules($fixers)
    ->setFinder($finder)
    ->setRiskyAllowed(true)
;

class PhpCsFixerLaravel {
    /**
     * Fixer configuration cache file.
     */
    const CACHE_FILE = '.php_cs_laravel.cache';

    /**
     * Upgrade guide cache file.
     */
    const UPGRADE_FILE = '.php_cs_laravel_upgrade.cache';

    const STYLECI_API_URL = 'https://api.styleci.io/presets';

    const PHP_CS_UPGRADE_URL = 'https://github.com/FriendsOfPHP/PHP-CS-Fixer/raw/2.15/UPGRADE.md';

    private $styleciToPhpcs = [
        'align_phpdoc' => ['phpdoc_align' => ['align' => 'vertical']],
        'length_ordered_imports' => ['ordered_imports' => ['sort_algorithm' => 'length']],
        'method_visibility_required' => 'visibility_required',
        'no_blank_lines_after_throw' => 'no_blank_lines_after_phpdoc',
        'no_blank_lines_between_imports' => null, // FIXME single_line_after_imports?
        'no_blank_lines_between_traits' => null, // FIXME
        'no_spaces_inside_offset' => 'no_spaces_around_offset',
        'post_increment' => 'pre_increment',
        'property_visibility_required' => 'visibility_required',
        'short_list_syntax' => null, // FIXME
        'unix_line_endings' => 'line_ending',
        'long_array_syntax' => ['array_syntax' => ['syntax' => 'long']],
        'short_array_syntax' => ['array_syntax' => ['syntax' => 'short']],
    ];

    /**
     * Get upgraded Laravel fixers.
     *
     * @return array
     */
    public function getFixers() {
        $styleciFixers = $this->readStyleciFixers();
        $rulesUpgrade = $this->readRulesUpgrade();
        $fixers = [];

        $upgrades = array_merge($rulesUpgrade, $this->styleciToPhpcs);

        // Convert StyleCI rule names to [$rule => true]
        array_map(function ($rule) use (&$fixers) {
            $fixers[$rule] = true;
        }, $styleciFixers);

        // Upgrade old rules
        array_walk($upgrades, function ($new, $old) use (&$fixers) {
            if (! isset($fixers[$old])) {
                return;
            }
            unset($fixers[$old]);
            // To be deleted
            if ($new === null) {
                return;
            }
            if (is_array($new)) {
                // Rule needs configuration
                $newKey = key($new);
                $fixers[$newKey] = $new[$newKey];
            } else {
                // Simple rename
                $fixers[$new] = true;
            }
        });

        return $fixers;
    }

    /**
     * Read cached Laravel rules from StyleCI API.
     *
     * @return array
     */
    private function readStyleciFixers() {
        // Check cache
        if (file_exists(self::CACHE_FILE)) {
            $fileContents = file_get_contents(self::CACHE_FILE);
            return json_decode($fileContents, true);
        }

        // Get fixers from StyleCI API
        $apiResponse = file_get_contents(self::STYLECI_API_URL);
        $allRuleSets = json_decode($apiResponse, true);
        $styleciFixers = [];
        array_map(function ($ruleSet) use (&$styleciFixers) {
            if ($ruleSet['name'] !== 'laravel') {
                return;
            }
            $styleciFixers = $ruleSet['fixers'];
        }, $allRuleSets);

        // Cache response
        $fileContents = json_encode($styleciFixers);
        file_put_contents(self::CACHE_FILE, $fileContents);

        return $styleciFixers;
    }

    /**
     * Read cached renamed rules from PHP CS Fixer upgrade guide.
     *
     * @return array
     */
    private function readRulesUpgrade() {
        // Check cache
        if (file_exists(self::UPGRADE_FILE)) {
            $fileContents = file_get_contents(self::UPGRADE_FILE);
            return json_decode($fileContents, true);
        }

        // Get relevant upgrade guide lines
        $fileContents = file_get_contents(self::PHP_CS_UPGRADE_URL);
        $upgradeLines = [];
        preg_match('/Renamed rules(.+)Changes to Fixers/s', $fileContents, $upgradeLines);

        // Parse lines to an associative array
        $upgrades = [];
        preg_match_all('/^([a-z]\S+)\s+\|\s+(\S+)\b.*$/m', $upgradeLines[1], $upgrades);
        $rulesUpgrade = array_combine($upgrades[1], $upgrades[2]);

        // Cache response
        $fileContents = json_encode($rulesUpgrade);
        file_put_contents(self::UPGRADE_FILE, $fileContents);

        return $rulesUpgrade;
    }
}
