<?php
/**
 * Document and Check PHP environment.
 *
 * Usage through a webserver
 *     wget -qO- "https://example.com/php-env-check.php" | jq .
 * Usage on PHP-CLI
 *     php ./php-env-check.php | jq .
 *
 * @package php-env-check
 * @author  Viktor Szépe <viktor@szepe.net>
 * @version 0.6.6
 *
 * @see https://github.com/psecio/iniscan
 */

namespace Toolkit4WP;

function check_env() {

    // Local access only: on PHP-CLI or on the webserver
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
    $status = empty( $check->diffs );

    // Display differences and exit
    print json_encode( $check->diffs );

    exit( $status ? 0 : 1 );
}

check_env();

/**
 * Get the difference of hardcoded values and the current PHP configuration.
 */
final class CheckEnv {

    /**
     * List of differences.
     */
    public $diffs = array();

    /**
     * Run the checks.
     */
    public function __construct() {

        // Engine version
        $this->assert( 'php', 70030, PHP_VERSION_ID );

        // Extensions for WordPress on PHP 7.0
        // http://wordpress.stackexchange.com/a/42212

        // Environment variables
        $this->assert( 'WP_ENV', 'production', getenv( 'WP_ENV' ) );
        $this->assert( 'WP_ENVIRONMENT_TYPE', 'production', getenv( 'WP_ENVIRONMENT_TYPE' ) );
        //$this->assert( 'APP_ENV', 'production', getenv( 'APP_ENV' ) );
        //$this->assert( 'AWS_CONFIG_FILE', '/home/user/website/aws-dummy-config', getenv( 'AWS_CONFIG_FILE' ) );

        // Core directives
        $this->assert_directive( 'short_open_tag', '' );
        $this->assert_directive( 'user_ini.filename', '' );
        $this->assert_directive( 'expose_php', '' );
        $this->assert_directive( 'allow_url_fopen', '' );
        $this->assert_directive( 'mail.add_x_header', '0' );
        $this->assert_directive( 'realpath_cache_size', '64k' );
        $this->assert_directive( 'output_buffering', '4096' );
        $this->assert_directive( 'max_input_time', '60' );
        $this->assert_directive( 'max_execution_time', '30' );
        $this->assert_directive( 'memory_limit', '128M' );
        $this->assert_directive( 'max_input_vars', '1000' );
        $this->assert_directive( 'post_max_size', '4M' );
        $this->assert_directive( 'upload_max_filesize', '4M' );
        $this->assert_directive( 'max_file_uploads', '20' );
        $this->assert_directive( 'display_errors', '' );

        // Compiled in Extensions
        // [ Core date filter hash libxml openssl pcntl pcre Reflection session SPL standard zlib ]
        // php -n -m | paste -s -d " "
        $this->assert_extension( 'date' );
        $this->assert_directive( 'date.timezone', 'UTC' );
        $this->assert_extension( 'filter' );
        $this->assert_extension( 'hash' );
        $this->assert_extension( 'openssl' );
        $this->assert_extension( 'pcre' );
        $this->assert_extension( 'SPL' );
        $this->assert_extension( 'zlib' );

        // Common Extensions
        // [ ctype iconv gettext tokenizer sockets pdo sysvsem fileinfo posix exif sysvmsg phar ftp calendar sysvshm shmop ]
        // dpkg -L php7.0-common | sed -n -e 's#^/usr/lib/php/\S\+/\(\S\+\)\.so$#\1#p' | paste -s -d " "
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
        // php7.0-xml: [ wddx xml simplexml xmlwriter xmlreader dom xsl ]
        $this->assert_extension( 'xml' );
        $this->assert_extension( 'SimpleXML' );
        $this->assert_extension( 'xmlreader' );
        $this->assert_extension( 'dom' );
        // php7.0-curl
        $this->assert_extension( 'curl' );
        // php7.0-gd
        $this->assert_extension( 'gd' );
        // php7.0-mysql: [ mysqlnd mysqli pdo_mysql ]
        // WP_USE_EXT_MYSQL will use mysqli through mysqlnd (no PDO)
        $this->assert_extension( 'mysqlnd' );
        $this->assert_extension( 'mysqli' );
        // php7.0-opcache
        $this->assert_extension( 'Zend OPcache', 'ext.opcache' );
        $this->assert_directive( 'opcache.restrict_api', '/home/prg123/website/' );
        $this->assert_directive( 'opcache.memory_consumption', '256' );
        $this->assert_directive( 'opcache.interned_strings_buffer', '16' );
        $this->assert_directive( 'opcache.max_accelerated_files', '10000' );

        // Deprecated Extensions
        $this->assert_disabled_extension( 'mcrypt' );
        $this->assert_disabled_extension( 'mysql' );

        // Disabled Extensions
        // [ calendar fileinfo pcntl PDO pdo_mysql Phar readline
        //   shmop sysvmsg(System V messages) sysvsem(System V semaphore) sysvshm(System V shared memory)
        //   wddx xmlwriter xsl ]
        $this->assert_disabled_extension( 'calendar' );
        $this->assert_disabled_extension( 'fileinfo' );
        // Compiled in: $this->assert_disabled_extension( 'pcntl' );
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
        // php7.0-sqlite3: [ pdo_sqlite sqlite3 ]
        $this->assert_disabled_extension( 'pdo_sqlite' );
        $this->assert_disabled_extension( 'sqlite3' );

        // 3rd-party Extensions

        // https://github.com/sektioneins/suhosin7
        $this->assert_disabled_extension( 'suhosin7' );
        $this->assert_disabled_extension( 'suhosin' );
        // php-redis, php-igbinary
        $this->assert_extension( 'igbinary' );
        $this->assert_extension( 'redis' );

        // php7.0-zip
        //$this->assert_extension( 'zip' );

        // php-imagick for PDF thumbnails
        $this->assert_extension( 'imagick' );

        // Argon2 hashing
        $this->assert_extension( 'sodium' );

        // Not for WordPress

        // Session
        $this->assert_extension( 'session' );
        $this->assert_directive( 'session.gc_maxlifetime', '1440' );

        // System program execution
        // Default disabled functions:
        // exec,shell_exec,system,popen,passthru,proc_open,pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority
        //$this->assert_function( 'proc_open' );

        // Directories
        $this->assert_directory( ini_get( 'upload_tmp_dir' ), 'dir.upload_tmp_dir' );
        $this->assert_directory( ini_get( 'sys_temp_dir' ), 'dir.sys_temp_dir' );
        $this->assert_directory( ini_get( 'session.save_path' ), 'dir.session_save_path' );

        /*
        // Database JSON data type support
        // See https://dev.mysql.com/doc/refman/5.7/en/json.html
        $dotenv = parse_ini_file( __DIR__ . '/html/.env' );
        $this->assert_version( 'mysqld.json', '5.7.8', $this->mysqli_innodb_version( $dotenv ) );
        $this->assert_version( 'mysqld.json', '5.7.8', $this->pdo_mysql_innodb_version( $dotenv ) );
        */

        /*
        // wkhtmltopdf
        chdir( __DIR__ . '/tmp' );
        $html = <<<EOF
<!DOCTYPE html><html><head><title>CC</title></head><body>
<p><img alt="Creative Commons" src="https://upload.wikimedia.org/wikipedia/commons/8/86/CC-logo.svg"></p>
</body></html>
EOF;
        $this->assert(
            'wkhtmltopdf',
            '4cfe353c60b4fab477c1ff5b8fd75369',
            $this->wkhtmltopdf( __DIR__ . '/vendor/bin/wkhtmltopdf-amd64', $html )
        );
        */
    }

    /**
     * Generic assertion.
     *
     * @param string $id       Assert ID
     * @param mixed  $expected Expected value
     * @param mixed  $result   Current value
     */
    private function assert( $id, $expected, $result ) {

        if ( $expected !== $result ) {
            $this->diffs[ $id ] = $result;
        }
    }

    /**
     * Assert for a PHP extension.
     *
     * @param string $extension_name Extension name
     * @param string $id             Optional assert ID
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
     * @param string $extension_name Extension name
     * @param string $id             Optional assert ID
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
     * @param string $directive_name Directive name
     * @param mixed  $expected       Expected value
     * @param string $id             Optional assert ID
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
     * @param string $function_name Function name
     * @param string $id            Optional assert ID
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
     * @param string $name            Thing that has a version
     * @param string $min_version     Expected version
     * @param string $current_version Current version
     * @param string $operator        Optional operator
     * @param string $id              Optional assert ID
     */
    private function assert_version( $name, $min_version, $current_version, $operator = '<=', $id = '' ) {

        // Automatic ID
        if ( '' === $id ) {
            $id = $name;
        }
        $this->assert( $id, true, version_compare( $min_version, $current_version, $operator ) );
    }

    /**
     * Assert for a directory.
     *
     * @param string|bool $directory Directory path
     * @param string $id             Assert ID
     */
    private function assert_directory( $directory, $id ) {

        if ( ! is_string( $directory ) || ! file_exists( $directory ) ) {
            $this->diffs[ $id ] = '!file_exists';

            return;
        }

        $this->assert( $id, true, is_writable( $directory ) );
    }

    /**
     * Get InnoDB version.
     *
     * @param array $config Datababase credentials
     * @return string
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
        if ( false === $link || mysqli_connect_errno() ) {
            return '0';
        }

        $result = $link->query( 'SELECT @@global.innodb_version;' );
        if ( is_bool( $result ) || 1 !== $result->num_rows ) {
            return '0';
        }

        $mysql_version = $result->fetch_row();
        $link->close();

        if ( null === $mysql_version ) {
            return '0';
        }

        return reset( $mysql_version );
    }

    /**
     * Get InnoDB version by PDO.
     *
     * @param array $config Datababase credentials
     * @return string
     */
    private function pdo_mysql_innodb_version( $config ) {

        if ( ! isset( $config['DB_HOST'] ) ) {
            return '0';
        }

        try {
            $link = new \PDO(
                sprintf(
                    'mysql:host=%s;port=%s;dbname=%s',
                    $config['DB_HOST'],
                    $config['DB_PORT'],
                    $config['DB_DATABASE']
                ),
                $config['DB_USERNAME'],
                $config['DB_PASSWORD']
            );
        } catch ( \PDOException $exception ) {
            return '0';
        }

        $result = $link->query( 'SELECT @@global.innodb_version;' );
        if ( false === $result || 1 !== $result->rowCount() ) {
            return '0';
        }

        $mysql_version = $result->fetchColumn();
        $link          = null;

        if ( ! is_string( $mysql_version ) ) {
            return '0';
        }

        return $mysql_version;
    }

    /**
     * Get consistent PDF checksum generated by wkhtmltopdf.
     *
     * @param string $path Path to wkhtmltopdf binary.
     * @param string $html HTML content to be converted.
     * @return string
     */
    private function wkhtmltopdf( $path, $html ) {

        // Create simple HTML file
        file_put_contents( 'cc.html', $html );

        // Run wkhtmltopdf
        $descriptors = array(
            0 => array( 'pipe', 'r' ),
            1 => array( 'pipe', 'w' ),
            2 => array( 'pipe', 'w' ),
        );
        $pipes       = array();
        $process     = proc_open( $path . ' --quiet cc.html cc.pdf', $descriptors, $pipes );
        $exit_status = proc_close( $process );
        unlink( 'cc.html' );
        if ( 0 !== $exit_status ) {
            return '-';
        }

        // Strip timestamp
        $pdf = file_get_contents( 'cc.pdf' );
        unlink( 'cc.pdf' );
        //                          /CreationDate (D:20181217215426Z)
        $stripped = preg_replace( '#/CreationDate \(D:[^)]+\)\n#', '', $pdf, 1 );

        // Return checksum
        return md5( $stripped );
    }
}
