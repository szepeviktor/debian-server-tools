<?php

// wget --post-data="auth=$(echo -n "${IP}${SECRET}"|shasum -a 256|cut -d" " -f1)&ip=${IP}" https://site/dnsbl.php

define( 'DNSBL_SECRET', '' );

// Above document root
define( 'DNSBL_DB', dirname( __DIR__ ) . '/dnsbl.sqlite' );

if ( 'cli' === php_sapi_name() ) {
    $_REQUEST['ip'] = $argv[1];
    $_REQUEST['auth'] = $argv[2];
}

if ( empty( $_REQUEST['auth'] ) || empty( $_REQUEST['ip'] ) ) {
    exit( 1 );
}

if ( ! authenticate( $_REQUEST['ip'], $_REQUEST['auth'] ) ) {
    exit( 2 );
}

$status = insert_ip( DNSBL_DB, $_REQUEST['ip'] ) ? 0 : 10;
exit( $status );

function authenticate( $ip, $data ) {

    $hash = hash( 'sha256', $ip . DNSBL_SECRET );
    return ( $data === $hash );
}

function insert_ip( $file, $ip, $type = 0 ) {

    $ipn = ip2long( $ip );

    if ( ! file_exists( $file )
        || (int) $ipn < 16777216
        || (int) $ipn > 4294967295
    ) {
        return false;
    }

    $now = time();

    $db = new PDO( 'sqlite:' . $file );
    $db->setAttribute( PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION );
    $db->setAttribute( PDO::ATTR_TIMEOUT, 3 );

    $insert = 'INSERT INTO instant VALUES ( :ip, :type, :date )';
    $stmt = $db->prepare( $insert );
    $stmt->bindParam( ':ip', $ipn, PDO::PARAM_INT );
    $stmt->bindParam( ':type', $type, PDO::PARAM_INT );
    $stmt->bindParam( ':date', $now, PDO::PARAM_INT );

    return $stmt->execute();
}
