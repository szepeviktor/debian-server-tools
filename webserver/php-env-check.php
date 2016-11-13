<?php
/**
 * Check PHP environment
 *
 * Usage through a webserver
 *     wget -q -O - "https://example.com/php-env-check.php"; echo
 * Usage on CLI
 *     php /path/to/php-env-check.php
 *
 * @package php-env-check
 */

namespace O1;

// Local access only
if ( php_sapi_name() !== 'cli' && $_SERVER['REMOTE_ADDR'] !== $_SERVER['SERVER_ADDR'] ) {
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
$check = new Check();
$status = empty( $check->errors );

// Display report and exit
print json_encode( $check->errors );
exit( $status ? 0 : 1 );

/**
 * Check PHP configuration.
 */
final class Check {

    /**
     * List of errors.
     */
    public $errors = array();

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

    /**
     * Run the checks.
     *
     * @param void
     */
    public function __construct() {

        // Engine version
        $this->assert( 'php', 50627, PHP_VERSION_ID );

        // Core directives
        $this->assert_directive( 'expose_php', '' );
        $this->assert_directive( 'realpath_cache_size', '64k' );
        $this->assert_directive( 'max_execution_time', '205' );
        $this->assert_directive( 'memory_limit', '256M' );

        $this->assert_directive( 'allow_url_fopen', '' );
        $this->assert_directive( 'max_input_vars', '6000' );
        $this->assert_directive( 'post_max_size', '3M' );
        $this->assert_directive( 'upload_max_filesize', '3M' );

        // Extensions
        $this->assert_extension( 'pdo_mysql' );
        $this->assert_extension( 'json' );
        $this->assert_extension( 'mbstring' );
        $this->assert_extension( 'mcrypt' );
        $this->assert_extension( 'curl' );
        $this->assert_extension( 'mssql' );

        // Opcache and its directives
        $this->assert_extension( 'Zend OPcache', 'ext.opcache' );
        $this->assert_directive( 'opcache.restrict_api', '/home/prg' );
        $this->assert_directive( 'opcache.memory_consumption', '256' );
        $this->assert_directive( 'opcache.interned_strings_buffer', '16' );
        $this->assert_directive( 'opcache.max_accelerated_files', '10000' );

        // Session directives
        $this->assert_directive( 'session.gc_maxlifetime', '259200' );

        // Datetime directives
        $this->assert_directive( 'date.timezone', 'Europe/Budapest' );
    }
}
