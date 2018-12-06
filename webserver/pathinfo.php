<?php
/**
 * Show path information elements.
 *
 * Origin: https://bugs.php.net/bug.php?id=60180
 * See also: https://httpd.apache.org/docs/2.4/mod/mod_proxy_fcgi.html#env
 * And: http://php.net/manual/en/ini.core.php#ini.cgi.fix-pathinfo
 */

function print_path_information() {

    $me = basename( __FILE__ );

    $row_template = '<tr><td class="e">%s</td><td class="v%s"><pre>%s</pre></td></tr>' . "\n";

    $server_elements = array(
        'proxy-fcgi-pathinfo' => '',
        'REQUEST_URI'         => sprintf( '/%s/path-info?parameter=value', $me ),
        'PHP_SELF'            => sprintf( '/%s/path-info', $me ),
        'SCRIPT_NAME'         => sprintf( '/%s', $me ),
        'SCRIPT_FILENAME'     => __FILE__,
        'PATH_INFO'           => '/path-info',
        'QUERY_STRING'        => 'parameter=value',
    );

    $output = '';

    if ( ! isset( $_GET['parameter'] ) ) {
        header( sprintf( 'Location: /%s/path-info?parameter=value', $me ) );
        exit;
    }

    // cgi.fix_pathinfo
    $output .= sprintf(
        $row_template,
        htmlspecialchars( 'cgi.fix_pathinfo' ),
        '',
        htmlspecialchars( ini_get( 'cgi.fix_pathinfo' ) )
    );

    // $_SERVER
    foreach ( $server_elements as $elem => $expected ) {
        $current = '';
        $class   = '';
        if ( isset( $_SERVER[ $elem ] ) ) {
            $current = $_SERVER[ $elem ];
            $class   = ( $current === $expected ) ? ' ok' : ' nok';
        }
        $output .= sprintf( $row_template, htmlspecialchars( $elem ), $class, htmlspecialchars( $current ) );
    }

    return $output;
}

$rows = print_path_information();
?>

<style type="text/css">
    body {background-color: #fff; color: #222; font-family: sans-serif; font-size: 16px;}
    td {padding: 3px 5px; min-width: 200px;}
    pre {margin: 0;}
    .e {background-color: #ccf;}
    .v {background-color: #ddd;}
    .ok {background-color: lightgreen;}
    .nok {background-color: red;}
</style>

<h1>Path information elements when using ProxyPass</h1>

<table>

    <?php print $rows; ?>

</table>

<a href="https://httpd.apache.org/docs/2.4/mod/mod_proxy_fcgi.html#env" target="_blank"><code>proxy-fcgi-pathinfo</code> environment variable</a>,
<a href="https://bugs.php.net/bug.php?id=74088" target="_blank">PATH_INFO is not set using PHP-FPM and mod_proxy_fcgi</a>,
<a href="https://bz.apache.org/bugzilla/show_bug.cgi?id=51517" target="_blank">mod_proxy_fcgi is not RFC 3875 compliant</a>
