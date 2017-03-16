<?php
/**
 * Check PHP environment.
 *
 * Usage through a webserver
 *     wget -q -O - "https://example.com/php-env-check.php"; echo
 * Usage on CLI
 *     php /path/to/php-env-check.php
 *
 * @package php-env-check
 * @version 0.2.1
 * @author Viktor Szépe <viktor@szepe.net>
 */

namespace O1;

// Local access only
if ( 'cli' !== php_sapi_name() && $_SERVER['REMOTE_ADDR'] !== $_SERVER['SERVER_ADDR'] ) {
    header( 'Status: 403 Forbidden' );
    header( 'HTTP/1.1 403 Forbidden', true, 403 );
    header( 'Connection: Close' );
    exit;
}

// Remove cached version of this file
if ( function_exists( 'opcache_invalidate' ) ) {
    opcache_invalidate( __FILE__ );
}

// Check environment
$check = new Check_Env();
$status = empty( $check->errors );

// Display report and exit
print json_encode( $check->errors );
exit( $status ? 0 : 1 );

/**
 * Check PHP configuration.
 */
final class Check_Env {

    /**
     * List of errors.
     */
    public $errors = array();

    /**
     * Run the checks.
     *
     * @param void
     */
    public function __construct() {

        // Engine version
        $this->assert( 'php', 70015, PHP_VERSION_ID );

        // Extensions for WordPress on PHP 7.0
        // http://wordpress.stackexchange.com/a/42212

        // Core directives
        $this->assert_directive( 'user_ini.filename', '' );
        $this->assert_directive( 'expose_php', '' );
        $this->assert_directive( 'allow_url_fopen', '0' );
        $this->assert_directive( 'mail.add_x_header', '' );
        $this->assert_directive( 'realpath_cache_size', '64k' );
        $this->assert_directive( 'max_execution_time', '30' );
        $this->assert_directive( 'memory_limit', '128M' );
        $this->assert_directive( 'max_input_vars', '1000' );
        $this->assert_directive( 'post_max_size', '4M' );
        $this->assert_directive( 'upload_max_filesize', '4M' );

        // Compiled in Extensions
        // php -n -m | paste -s -d " "
        // Core date filter hash libxml openssl pcntl pcre Reflection session SPL standard zlib
        $this->assert_extension( 'date' );
        $this->assert_directive( 'date.timezone', 'Europe/Budapest' );
        $this->assert_extension( 'filter' );
        $this->assert_extension( 'hash' );
        $this->assert_extension( 'openssl' );
        $this->assert_extension( 'pcre' );
        $this->assert_extension( 'SPL' );
        $this->assert_extension( 'zlib' );

        // Common Extensions
        // dpkg -L php7.0-common | sed -n -e 's|^/usr/lib/php/\S\+/\(\S\+\)\.so$|\1|p' | paste -s -d " "
        // ctype iconv gettext tokenizer sockets pdo sysvsem fileinfo posix exif sysvmsg phar ftp calendar sysvshm shmop
        $this->assert_extension( 'ctype' ); // wp-includes/ID3/getid3.lib.php
        $this->assert_extension( 'posix' );
        $this->assert_extension( 'exif' ); // wp-admin/includes/image.php
        $this->assert_extension( 'ftp' );
        $this->assert_extension( 'gettext' ); // _()
        $this->assert_extension( 'iconv' );
        $this->assert_extension( 'mbstring' );
        $this->assert_extension( 'sockets' );
        $this->assert_extension( 'tokenizer' );

        // php7.0-json
        $this->assert_extension( 'json' );
        // php7.0-intl
        $this->assert_extension( 'intl' );
        // php7.0-xml
        // wddx xml simplexml xmlwriter xmlreader dom xsl
        $this->assert_extension( 'xml' );
        $this->assert_extension( 'SimpleXML' );
        $this->assert_extension( 'xmlreader' );
        $this->assert_extension( 'dom' );
        // php7.0-curl
        $this->assert_extension( 'curl' );
        // php7.0-gd
        $this->assert_extension( 'gd' );
        // php7.0-mysql
        // mysqlnd mysqli pdo_mysql
        // WP_USE_EXT_MYSQL will use mysqli through mysqlnd (no PDO)
        $this->assert_extension( 'mysqlnd' );
        $this->assert_extension( 'mysqli' );
        // php7.0-opcache
        $this->assert_extension( 'Zend OPcache', 'ext.opcache' );
        $this->assert_directive( 'opcache.restrict_api', '/home/prg123' );
        $this->assert_directive( 'opcache.memory_consumption', '256' );
        $this->assert_directive( 'opcache.interned_strings_buffer', '16' );
        $this->assert_directive( 'opcache.max_accelerated_files', '10000' );

        // Deprecated Extensions
        $this->assert_disabled_extension( 'mcrypt' );
        $this->assert_disabled_extension( 'mysql' );

        // Disabled Extensions
        // calendar fileinfo pcntl PDO pdo_mysql Phar readline
        // shmop sysvmsg(System V messages) sysvsem(System V semaphore) sysvshm(System V shared memory) wddx xmlwriter xsl
        $this->assert_disabled_extension( 'calendar' );
        $this->assert_disabled_extension( 'fileinfo' );
        // Compiled in
        //$this->assert_disabled_extension( 'pcntl' );
        $this->assert_disabled_extension( 'PDO' );
        $this->assert_disabled_extension( 'pdo_mysql' );
        $this->assert_disabled_extension( 'Phar' );
        $this->assert_disabled_extension( 'readline' );
        $this->assert_disabled_extension( 'shmop' );
        $this->assert_disabled_extension( 'sysvmsg' );
        $this->assert_disabled_extension( 'sysvsem' );
        $this->assert_disabled_extension( 'sysvshm' );
        $this->assert_disabled_extension( 'wddx' );
        $this->assert_disabled_extension( 'xmlwriter' );
        $this->assert_disabled_extension( 'xsl' );
        // php7.0-sqlite3
        // pdo_sqlite sqlite3
        $this->assert_disabled_extension( 'pdo_sqlite' );
        $this->assert_disabled_extension( 'sqlite3' );

        // 3rd-party Extensions

        // php7.0-redis
        $this->assert_extension( 'igbinary' );
        $this->assert_extension( 'redis' );

        // Not for WordPress

        // Session
        $this->assert_extension( 'session' );
        $this->assert_directive( 'session.gc_maxlifetime', '1440' );
    }

    /**
     * Simple assert.
     *
     * @param $id string       Assert ID
     * @param $expected string Expected value
     * @param $result string   Current value
     */
    private function assert( $id, $expected, $result ) {

        if ( $expected !== $result ) {
            $this->errors[ $id ] = $result;
        }
    }

    /**
     * Assert for a PHP extension.
     *
     * @param $extension_name string Extension name
     * @param $id string             Optional assert ID
     */
    private function assert_extension( $extension_name, $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = 'ext.' . $extension_name;
        }
        $this->assert( $id, true, extension_loaded( $extension_name ) );
    }

    /**
     * Negative assert for a PHP extension.
     *
     * @param $extension_name string Extension name
     * @param $id string             Optional assert ID
     */
    private function assert_disabled_extension( $extension_name, $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = '!ext.' . $extension_name;
        }
        $this->assert( $id, false, extension_loaded( $extension_name ) );
    }

    /**
     * Assert for a PHP directive.
     *
     * @param $directive_name string Directive name
     * @param $expected string       Expected value
     * @param $id string             Optional assert ID
     */
    private function assert_directive( $directive_name, $expected, $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = $directive_name;
        }
        $this->assert( $id, $expected, ini_get( $directive_name ) );
    }
}
