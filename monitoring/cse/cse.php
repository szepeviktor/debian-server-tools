<?php
/*
Snippet Name: Can-send-email slave
Version: 0.2.0
Description: Send a trigger email.
Snippet URI: https://github.com/szepeviktor/debian-server-tools
License: The MIT License (MIT)
Author: Viktor Szépe
*/

define( 'MAIL_EOL', "\r\n" );

// CSE address
$to = 'cse@worker.szepe.net';

// http://www.randomtext.me/download/txt/gibberish/p-5/20-35
$message_template = '
Much bowed when mammoth for lusciously lost a dear whooped some ouch
insufferably one indefatigably contemplated manifestly therefore much
mongoose and llama far feeble a cocky.

Robin the whistled scorpion mongoose fleetly past together toucan compulsively
coarsely inadvertent far hence within when up prissily amicable one and since
gawked jollily rude.

Met patiently excluding because and far sleazily sufficiently hyena enormously
that goodness much hawk mastodon walking this this whale ouch shed kookaburra
sleekly that one the affably.

Alarmingly much this the inoffensive in more much sobbed aboard reined that
labrador ordered much less jeez gibbered checked a wove selflessly goodness
this adjusted honey flustered a that turtle unavoidable hello messily.

Cringed apart complete bat knitted impulsively domestic behind jokingly a far
jeepers folded blubbered wildebeest lighthearted much exultingly yikes yawned
well winced swept far slowly decorously.
';

$server = isset( $_SERVER['SERVER_NAME'] ) ? $_SERVER['SERVER_NAME'] : $_SERVER['HTTP_HOST'];
$headers = sprintf( 'X-Mailer: PHP/%s%sX-Host: %s',
    phpversion(),
    MAIL_EOL,
    $server
);
$subject = sprintf( '[cse] ping from %s', $server );

// Shuffle text
$message_words = explode( ' ', $message_template );
shuffle( $message_words );
$message = implode( ' ' , $message_words );

// @TODO Rewrite mu-smtp-uri/smtp-uri.php for PHPMailer

$mail = mail( $to, $subject, $message, $headers );

if ( true !== $mail ) {
    printf( 'CSE mail() returned: %s', var_export( $mail, true ) );
}
