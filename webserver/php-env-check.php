<?php
/**
 * Check PHP environment.
 *
 * Usage through a webserver
 *     wget -qO- "https://example.com/php-env-check.php" | jq .
 * Usage on CLI
 *     php ./php-env-check.php | jq .
 *
 * @package php-env-check
 * @author  Viktor Szépe <viktor@szepe.net>
 * @version 0.4.0
 */

namespace O1;

checkEnv();

function checkEnv() {

    // Local access only
    if ( 'cli' !== php_sapi_name() && $_SERVER['REMOTE_ADDR'] !== $_SERVER['SERVER_ADDR'] ) {
        header( 'Status: 403 Forbidden' );
        header( 'HTTP/1.1 403 Forbidden', true, 403 );
        header( 'Connection: Close' );

        exit;
    }

    // Remove cached version of this file
    if ( function_exists( 'opcache_invalidate' ) ) {
        @opcache_invalidate( __FILE__ );
    }

    // Check environment
    $check  = new CheckEnv();
    $status = empty( $check->errors );

    // Display report and exit
    print json_encode( $check->errors );

    exit( $status ? 0 : 1 );
}

/**
 * Check PHP configuration.
 */
final class CheckEnv {

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
        $this->assert( 'php', 70020, PHP_VERSION_ID );

        // Extensions for WordPress on PHP 7.0
        // http://wordpress.stackexchange.com/a/42212

        // Environment variables
        $this->assert( 'WP_ENV', 'production', getenv( 'WP_ENV' ) );
        //$this->assert( 'APP_ENV', 'production', getenv( 'APP_ENV' ) );

        // Core directives
        $this->assert_directive( 'user_ini.filename', '' );
        $this->assert_directive( 'expose_php', '' );
        $this->assert_directive( 'allow_url_fopen', '' );
        $this->assert_directive( 'mail.add_x_header', '0' );
        $this->assert_directive( 'realpath_cache_size', '64k' );
        $this->assert_directive( 'output_buffering', '4096' );
        $this->assert_directive( 'max_execution_time', '30' );
        $this->assert_directive( 'memory_limit', '128M' );
        $this->assert_directive( 'max_input_vars', '1000' );
        $this->assert_directive( 'post_max_size', '4M' );
        $this->assert_directive( 'upload_max_filesize', '4M' );
        $this->assert_directive( 'display_errors', '' );

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
        // dpkg -L php7.2-common | sed -n -e 's|^/usr/lib/php/\S\+/\(\S\+\)\.so$|\1|p' | paste -s -d " "
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

        // php7.2-json
        $this->assert_extension( 'json' );
        // php7.2-intl
        $this->assert_extension( 'intl' );
        // php7.2-xml
        // wddx xml simplexml xmlwriter xmlreader dom xsl
        $this->assert_extension( 'xml' );
        $this->assert_extension( 'SimpleXML' );
        $this->assert_extension( 'xmlreader' );
        $this->assert_extension( 'dom' );
        // php7.2-curl
        $this->assert_extension( 'curl' );
        // php7.2-gd
        $this->assert_extension( 'gd' );
        // php7.2-mysql
        // mysqlnd mysqli pdo_mysql
        // WP_USE_EXT_MYSQL will use mysqli through mysqlnd (no PDO)
        $this->assert_extension( 'mysqlnd' );
        $this->assert_extension( 'mysqli' );
        // php7.2-opcache
        $this->assert_extension( 'Zend OPcache', 'ext.opcache' );
        $this->assert_directive( 'opcache.restrict_api', '/home/prg123/website/' );
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
        // php7.2-sqlite3
        // pdo_sqlite sqlite3
        $this->assert_disabled_extension( 'pdo_sqlite' );
        $this->assert_disabled_extension( 'sqlite3' );

        // 3rd-party Extensions

        // php-redis
        $this->assert_extension( 'igbinary' );
        $this->assert_extension( 'redis' );

        // Not for WordPress

        // Session
        $this->assert_extension( 'session' );
        $this->assert_directive( 'session.gc_maxlifetime', '1440' );

        // System program execution
        //$this->assert_function( 'proc_open' );

        // Database JSON data type support
        // See https://dev.mysql.com/doc/refman/5.7/en/json.html
        //$dotenv = parse_ini_file( __DIR__ . '/html/.env' );
        //$this->assert_version( 'mysqld.json', '5.7.8', $this->mysqli_innodb_version( $dotenv ) );
        //$this->assert_version( 'mysqld.json', '5.7.8', $this->pdo_mysql_innodb_version( $dotenv ) );
    }

    /**
     * Generic assertion.
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

    /**
     * Assert for a PHP function.
     *
     * @param $function_name string  Function name
     * @param $expected string       Expected value
     * @param $id string             Optional assert ID
     */
    private function assert_function( $function_name, $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = $function_name;
        }
        $this->assert( $id, true, function_exists( $function_name ) );
    }

    /**
     * Assert for a version.
     *
     * @param $name string              Thing that has a version
     * @param $min_version string       Expected version
     * @param $current_version string   Current version
     * @param $operator string          Optional operator
     * @param $id string                Optional assert ID
     */
    private function assert_version( $name, $min_version, $current_version, $operator = '<=', $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = $name;
        }
        $this->assert( $id, true, version_compare( $min_version, $current_version, $operator ) );
    }

    /**
     * Get InnoDB version.
     *
     * @param $config array Datababase credentials
     */
    private function mysqli_innodb_version( $config ) {

        if ( ! isset( $config['DB_HOST'] ) ) {
            return '0';
        }

        $link = mysqli_connect(
            $config['DB_HOST'],
            $config['DB_USERNAME'],
            $config['DB_PASSWORD'],
            $config['DB_DATABASE'],
            $config['DB_PORT']
        );
        if ( mysqli_connect_errno() ) {
            return '0';
        }

        $result = $link->query( 'SELECT @@global.innodb_version;' );
        if ( 1 !== $result->num_rows ) {
            return '0';
        }

        $mysql_version = $result->fetch_row();
        $link->close();

        return reset( $mysql_version );
    }

    /**
     * Get InnoDB version by PDO.
     *
     * @param $config array Datababase credentials
     */
    private function pdo_mysql_innodb_version( $config ) {

        if ( ! isset( $config['DB_HOST'] ) ) {
            return '0';
        }

        try {
            $link = new \PDO( sprintf( 'mysql:host=%s;port=%s;dbname=%s',
                $config['DB_HOST'],
                $config['DB_PORT'],
                $config['DB_DATABASE']
            ), $config['DB_USERNAME'], $config['DB_PASSWORD'] );
        } catch ( \PDOException $exception ) {
            return '0';
        }

        $result = $link->query( 'SELECT @@global.innodb_version;' );
        if ( 1 !== $result->rowCount() ) {
            return '0';
        }

        $mysql_version = $result->fetchColumn();
        $link          = null;

        return $mysql_version;
    }
}
