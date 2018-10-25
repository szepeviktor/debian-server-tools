<?php

namespace Bouncedsn;

use Dotenv\Dotenv;
use Analog\Analog;
use Analog\Handler\LevelName;
use Analog\Handler\File;
use Analog\Handler\Stderr;
use PHPMailer\PHPMailer\PHPMailer;

final class Bouncedsn {

    /**
     * Create, log and send Bounce Delivery Status Notification.
     */
    public function __construct() {

        $dotenv = new Dotenv( __DIR__ . '/..' );
        $dotenv->load();
        $providerName = getenv('BOUNCEDSN_PROVIDER');
        $to = getenv('BOUNCEDSN_TO');
        $from = getenv('BOUNCEDSN_FROM');

        // Logging
        $this->logSetup();

        // Provider
        if ( ! is_string( $providerName ) ) {
            Analog::alert( 'Not configured provider name.' );
            return;
        }
        $providerName  = ucfirst( $providerName );
        $providerClass = '\\Bouncedsn\\Provider\\' . $providerName; #'
        if ( ! class_exists( $providerClass ) ) {
            Analog::alert( 'Non-existent provider.' );
            return;
        }

        // Mailing
        if ( ! filter_var( $to, FILTER_VALIDATE_EMAIL ) ) {
            Analog::alert( 'Invalid recipient address.' );
            return;
        }
        if ( empty( $to ) ) {
            $to = 'postmaster';
        }
        if ( empty( $from ) ) {
            $from = $to;
        }
        $mail          = new PHPMailer();
        $mail->CharSet = 'utf-8';
        $mail->XMailer = 'BounceDSN v' . $this->getVersion();
        $mail->setFrom( $from, $providerName . ' Notification' );
        $mail->addAddress( $to );

        $input = 'php://input';
        if ( 'cli' === php_sapi_name() ) {
            $input = 'php://stdin';
        }
        // Instantiate provider class
        $provider = new $providerClass( file_get_contents( $input ), $mail );
        if ( true !== $provider->processing ) {
            return;
        }
        // Send DSN
        if ( ! $mail->send() ) {
            Analog::error( 'BounceDSN sending failed: ' . $mail->ErrorInfo );
        }
    }

    /**
     * Set up logging
     */
    private function logSetup() {

        // Log to a file
        if ( $logPath = getenv( 'BOUNCEDSN_LOG' ) ) {
            Analog::handler( LevelName::init( File::init( $logPath ) ) );
            Analog::$date_format = '@U';
            Analog::$format = '%2$s|%3$d|%4$s' . "\n";

            return;
        }

        // Log to stderr
        Analog::handler( LevelName::init( Stderr::init() ) );
        Analog::$format = 'Bounce DSN.%3$s: %4$s';
    }

    /**
     * Get package version from Composer
     */
    private function getVersion() {

        $composerFile = __DIR__ . '/../composer.json';
        if ( ! file_exists( $composerFile ) ) {

            return 'n/a';
        }
        $composerConfig = json_decode( (string) file_get_contents( $composerFile ) );
        if ( false === $composerConfig || ! property_exists(  $composerConfig, 'version' ) ) {

            return 'unknown';
        }

        return $composerConfig->version;
    }
}
