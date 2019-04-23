<?php declare(strict_types = 1);
/**
 * A Proper PHP class declares Strict Typing (introduced in PHP 7).
 *
 * File comment informs humans what this is all about.
 * Please use LF line ends.
 * Consider writing your code in `vendor/bin/phpcs --standard=PSR12`
 * @see https://github.com/php-fig/fig-standards/blob/master/proposed/extended-coding-style-guide.md
 *
 * @package Properclass
 * @version 1.0.0
 */

namespace ProperNameSpace;

/**
 * This is a proper class comment.
 *
 * There must not be any code (require, if, new etc.) OUTSIDE the 1 class.
 */
final class OneClassPerFile
{
    /**
     * Proper property definition.
     *
     * All propertied must be defined and have a PHPDoc.
     *
     * @var array
     */
    public $defineAllProperties = array();

    /**
     * Proper PHPDoc.
     *
     * @param string $codingStyle The coding style used.
     */
    public function __construct($codingStyle)
    {
        if ($codingStyle === '') {
            echo 'No side effects like this please!';
        }
        define('NO_CONSTANTS', 'Classes must not define GLOBAL constants.');
        $this->doNotDoThis = 'Please do not introduce undefined properties!';
    }

    /**
     * Proper PHPDoc for all methods.
     *
     * @param string $keepMethodsShort
     * @return bool
     */
    private function oneOperationPerMethod($keepMethodsShort) : bool
    {
        if ($keepMethodsShort === 'I do my one job') {
            return true;
        }
        // 1 operation per method
        return false;
    }

    /**
     * Bad parts of PHP.
     *
     * @see https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/
     *
     * @param array $list
     */
    public function badPartsOfPhp(array $list)
    {
        // Resist the temptation, avoid bad parts of PHP
        extract($list, EXTR_SKIP);
        $thisIsABigNo = compact($varname1, $varname2);
        if ($oneType == $otherType) {
            $thisIsABigNo[] = 'Must not use loose comparision';
        }
        if (! $varname1) {
            $thisIsABigNo[] = 'Casting a variable as boolean must be avioided';
            // ! is only for booleans
        }
        if (empty($thisIsABigNo)) {
            $thisIsABigNo[] = 'empty() is so complex, you must avoid it';
            // empty on arrays: $array === []
            // empty on strings: $string === ''
        }
    }
}
// phpcs:ignore PSR2.Files.ClosingTag.NotAllowed
// No closing PHP tag ?>
