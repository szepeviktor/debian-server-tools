<?php declare(strict_types = 1);

/**
 * Read JSON file and compare with data from PHP.
 */
final class AcfExportChecker
{
    const ACF_JSON_TPL = './acf-json/%s.json';

    protected $field_group;

    public static $runCount = 0;

    public function __construct(array $field_group)
    {
        $this->field_group = $field_group;
    }

    public function check(): bool
    {
        self::$runCount += 1;

        $contents = file_get_contents(sprintf(self::ACF_JSON_TPL, $this->field_group['key']));
        if ($contents === false) {
            throw new \Exception('Failed to open JSON file for ' . $this->field_group['key']);
        }

        // Get associative array from JSON.
        $json = json_decode($contents, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new \UnexpectedValueException('Failed to parse JSON content in ' . $this->field_group['key']);
        }

        // Suppress difference in "modified" field.
        unset($json['modified'], $this->field_group['modified']);

        // Check equality only.
        return $this->field_group == $json;
    }
}

/**
 * Core's add_filter() stubs.
 */
function add_filter($p1, $p2)
{
}

/**
 * Hijacked ACF field group function.
 */
function acf_add_local_field_group(array $field_group): void
{
    global $checkExitStatus;

    $checker = new AcfExportChecker($field_group);
    if (!$checker->check()) {
        $checkExitStatus += 1;
        error_log('Difference found in ' . $field_group['key']);
    }
}

// Global.
$checkExitStatus = 0;

// Start acf_add_local_field_group() calls.
require './acf-json/acf-fields.php';

// Compare counts.
if (AcfExportChecker::$runCount !== count(glob('./acf-json/group_*.json'))) {
    throw new \Exception('Different number of field groups!');
}

exit($checkExitStatus);
