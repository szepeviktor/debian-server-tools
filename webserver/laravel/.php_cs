<?php // phpcs:ignore PSR1.Files.SideEffects.FoundWithSymbols

/**
 * Convert Laravel presets from StyleCI to PHP CS Fixer.
 *
 * 1. Install PHP CS Fixer: phive install php-cs-fixer
 * 2. Start: tools/php-cs-fixer fix -v --dry-run
 *
 * @see https://docs.styleci.io/presets#laravel
 * @see https://github.com/matt-allan/laravel-code-style
 * @version 1.3.0
 */

declare(strict_types=1);

return PhpCsFixer\Config::create()
    ->setRules((new PhpCsFixerLaravel())->getFixers())
    ->setFinder(PhpCsFixer\Finder::create()->in(__DIR__ . '/app'))
    ->setRiskyAllowed(true)
;

// phpcs:ignore PSR1.Classes.ClassDeclaration.MissingNamespace
final class PhpCsFixerLaravel
{
    /**
     * Fixer configuration cache file.
     *
     * @var string
     */
    public const CACHE_FILE = '.php_cs_laravel.cache';

    /**
     * Upgrade guide cache file.
     *
     * @var string
     */
    public const UPGRADE_FILE = '.php_cs_laravel_upgrade.cache';

    /**
     * StyleCI API URL.
     *
     * @var string
     */
    public const STYLECI_API_URL = 'https://api.styleci.io/presets';

    /**
     * PHP CS Fixer upgrade guide document URL.
     *
     * @var string
     */
    public const PHP_CS_UPGRADE_URL = 'https://github.com/FriendsOfPHP/PHP-CS-Fixer/raw/v2.15.10/UPGRADE.md';

    /**
     * Conversions from StyleCI to PHP CS Fixer.
     *
     * @var array
     */
    protected $styleciToPhpcs = [
        // TODO Laravel double space in PHPDoc: 'align_phpdoc' => null,
        'align_phpdoc' => ['phpdoc_align' => ['align' => 'vertical']],
        'alpha_ordered_imports' => ['ordered_imports' => ['sort_algorithm' => 'alpha']],
        'die_to_exit' => 'no_alias_language_construct_call',
        'length_ordered_imports' => ['ordered_imports' => ['sort_algorithm' => 'length']],
        'long_array_syntax' => ['array_syntax' => ['syntax' => 'long']],
        'method_visibility_required' => 'visibility_required',
        'no_blank_lines_after_throw' => 'no_blank_lines_after_phpdoc',
        'no_blank_lines_between_imports' => ['no_extra_blank_lines' => ['tokens' => ['use']]],
        'no_blank_lines_between_traits' => ['no_extra_blank_lines' => ['tokens' => ['use_trait']]],
        'no_spaces_inside_offset' => 'no_spaces_around_offset',
        'no_unused_lambda_imports' => 'lambda_not_used_import',
        'post_increment' => 'pre_increment',
        'property_visibility_required' => 'visibility_required',
        'psr12_braces' => 'braces',
        'short_array_syntax' => ['array_syntax' => ['syntax' => 'short']],
        'short_list_syntax' => ['list_syntax' => ['syntax' => 'short']],
        'unix_line_endings' => 'line_ending',
        // TODO Coming in v3.0 https://github.com/FriendsOfPHP/PHP-CS-Fixer/tree/3.0
        'clean_namespace' => null,
        'phpdoc_inline_tag_normalizer' => null,
        'phpdoc_singular_inheritdoc' => null,
        'switch_continue_to_break' => null,
    ];

    /**
     * Get upgraded Laravel fixers.
     *
     * @return array
     */
    public function getFixers()
    {
        $upgrades = array_merge($this->readRulesUpgrade(), $this->styleciToPhpcs);

        // Convert StyleCI rule names to [$rule => true]
        // Start with PSR-2
        $fixers = array_reduce($this->readStyleciFixers(), function ($stack, $rule) {
            return $stack + [$rule => true];
        }, ['@PSR2' => true]);

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

            // Rule needs configuration
            if (is_array($new)) {
                $newKey = key($new);
                $fixers[$newKey] = $new[$newKey];

                return;
            }

            // Simple rename
            $fixers[$new] = true;
        });

        // Strict types
        $fixers['declare_strict_types'] = true;

        return $fixers;
    }

    /**
     * Read cached Laravel rules from StyleCI API.
     *
     * @return array
     */
    protected function readStyleciFixers()
    {
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
            // array_merge(...array_values($ruleSet['fixers']));
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
    protected function readRulesUpgrade()
    {
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
