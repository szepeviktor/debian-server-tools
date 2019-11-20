<?php

namespace I18n;

/**
 * Generate string of all latin accented characters.
 */
class LatinAccents
{

    /**
     * Cache characters in a PHP file.
     */
    public function __construct()
    {
        file_put_contents('./latin-accented-characters.php', sprintf(
            "<?php\n\$return '%s';\n",
            $this->getModernLatinCharacters()
        ));
    }

    /**
     * Return characters of a given UNICODE range as a UTF-8 string.
     *
     * @link https://en.wikipedia.org/wiki/Unicode_block
     *
     * @param int $first
     * @param int $last
     * @return string
     */
    private function getUnicodeRange(int $first, int $last)
    {
        if ($last < $first) {
            return '';
        }

        $unicode = '';
        for ($c = $first; $c <= $last; $c++) {
            $highByte = ($c >> 8);
            $lowByte  = ($c & 0xFF);
            $unicode .= sprintf('%c%c', $lowByte, $highByte);
        }

        return iconv('UNICODE', 'UTF-8', $unicode);
    }

    /**
     * Return modern - mainly european - latin characters.
     *
     * @return string
     */
    private function getModernLatinCharacters()
    {
        $latin = '';

        // Latin-1 Supplement (0080-00FF)
        // @link https://en.wikipedia.org/wiki/Latin-1_Supplement_(Unicode_block)
        // Letters
        $latin .= $this->getUnicodeRange(0x00C0, 0x00D6);
        // Letters
        $latin .= $this->getUnicodeRange(0x00D8, 0x00F6);
        // Letters
        $latin .= $this->getUnicodeRange(0x00F8, 0x00FF);

        // Latin Extended-A (0100-017F)
        // @link https://en.wikipedia.org/wiki/Latin_Extended-A
        // European Latin
        $latin .= $this->getUnicodeRange(0x0100, 0x0148);
        // European Latin
        $latin .= $this->getUnicodeRange(0x014A, 0x017F);

        // Latin Extended-B (0180-024F)
        // @link https://en.wikipedia.org/wiki/Latin_Extended-B
        // Croatian digraphs matching Serbian Cyrillic letters
        $latin .= $this->getUnicodeRange(0x01C4, 0x01CC);
        // Pinyin (chinese) diacritic-vowel combinations
        $latin .= $this->getUnicodeRange(0x01CD, 0x01DC);
        // Additions for Slovenian and Croatian
        $latin .= $this->getUnicodeRange(0x0200, 0x0217);
        // Additions for Romanian
        $latin .= $this->getUnicodeRange(0x0218, 0x021B);
        // Miscellaneous additions
        $latin .= $this->getUnicodeRange(0x021C, 0x0229);
        // Additions for Livonian
        $latin .= $this->getUnicodeRange(0x022A, 0x0233);

        return $latin;
    }
}
