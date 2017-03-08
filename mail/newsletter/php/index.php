<!DOCTYPE html>
<html>
<head>
    <title>TITLE</title>
    <meta name="robots" content="noindex, nofollow">
    <style type="text/css">
        html {background:white;}
    </style>
</head>
<body>

<?php

$log = '/home/user/website' . '/unsub.log';
$prefix = 'ID:';

// Campaign, email address, hash
if (!empty($_GET['c']) && !empty($_GET['e']) && !empty($_GET['h'])) {
    // Check hash
    include_once __DIR__ . '/PseudoCrypt.php';
    $message = 'invalid_hash';
    $id = hexdec(hash('crc32b', $prefix . trim($_GET['e'])));
    $hash = \PseudoCrypt\PseudoCrypt::hash($id, 6);
    if ($hash === trim($_GET['h'])) {
        $message = 'OK';
    }
    $unsub_item = sprintf(
        '@%d|%s|%s|%s|%s|%s',
        time(),
        $_SERVER['REMOTE_ADDR'],
        trim($_GET['c']),
        trim($_GET['e']),
        trim($_GET['h']),
        $message
    );
    file_put_contents($log, $unsub_item . "\n", FILE_APPEND | LOCK_EX);

    ?>
    <script>
        alert("A leiratkozási kérelmét rögzítettük.");
        window.location = "/";
    </script>
    <?php
}
?>

</body>
</html>
