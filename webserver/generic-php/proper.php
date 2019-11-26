<?php declare(strict_types = 1);

/**
 * A Proper PHP class file declares Strict Typing (introduced in PHP 7).
 *
 * File comment informs humans what this is all about.
 * Please use LF line ends.
 * Turn off execution bit of PHP files.
 * See proper-phpcs.xml
 *
 * @package Properclass
 * @author Proper Developer <proper@developer.test>
 * @license https://opensource.org/licenses Example-Licence
 * @see https://github.com/php-fig/fig-standards/blob/master/proposed/extended-coding-style-guide.md
 */

namespace ProperNameSpace;

/**
 * This is a proper class comment.
 *
 * There must not be any code (require, define, if, new etc.) OUTSIDE the 1 class.
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
    private function oneOperationPerMethod($keepMethodsShort): bool
    {
        if ($keepMethodsShort !== 'I do my one job') {
            return false;
        }
        // 1 operation per method
        return true;
    }

    /**
     * Bad parts of PHP.
     *
     * @see https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/
     *
     * @param array $list
     * @return void
     */
    public function badPartsOfPhp(array $list): void
    {
        // Resist the temptation, avoid bad parts of PHP
        extract($list, EXTR_SKIP);
        $thisIsABigNo = compact($varname1, $varname2);
        if ($oneType == $otherType) {
            $thisIsABigNo[] = 'Must not use loose comparision';
        }
        if (! $varname1) {
            $thisIsABigNo[] = 'Casting a variable as boolean must be avioided';
            // `if` is only for booleans
        }
        if (empty($thisIsABigNo)) {
            $thisIsABigNo[] = 'empty() is so complex, you must avoid it';
            // empty on arrays: $array === []
            // empty on strings: $string === ''
        }
    }

    /**
     * Errors go into if-s, normal execution goes without indentation.
     *
     * @param int $value
     * @return string|null
     */
    function errorsInIf(int $value): ?string
    {
        if ($value > 1) {
            return null;
        }

        return 'This value is okay: '.strval($value);
    }
}
// phpcs:ignore PSR2.Files.ClosingTag.NotAllowed
// No closing PHP tag ?>
