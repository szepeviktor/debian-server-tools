<?php
/*
Snippet Name: Can-send-email slave
Snippet URI: https://github.com/szepeviktor/debian-server-tools
Description: Send a trigger email.
Version: 0.1.1
License: The MIT License (MIT)
Author: Viktor Szépe
Author URI: http://www.online1.hu/webdesign/
*/

// Set the CSE address here.
$to = "cse@worker.szepe.net";

define( 'MAIL_EOL', "\r\n" );
$server = isset( $_SERVER['SERVER_NAME'] ) ? $_SERVER['SERVER_NAME'] : $_SERVER['HTTP_HOST'];
$headers = "X-Mailer: PHP/" . phpversion();
$headers .= MAIL_EOL . "X-Host: {$server}";
$subject = "[cse] ping from {$server}";
// http://www.randomtext.me/download/txt/gibberish/p-5/20-35
$message = '
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

// Shuffle text
$message_words = explode( ' ', $message );
shuffle( $message_words );
$message = implode( ' ' , $message_words );

// @TODO rewrite mu-smtp-uri/smtp-uri.php for phpmailer

$mail = mail( $to, $subject, $message, $headers );

if ( true !== $mail ) {
    print "mail() returned: " . var_export( $mail, true );
}
