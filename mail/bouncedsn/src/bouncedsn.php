<?php

namespace Bouncedsn;

use Analog\Analog;
use Analog\Handler\File;
use Analog\Handler\Stderr;
use PHPMailer\PHPMailer\PHPMailer;

final class Bouncedsn {

    /**
     * Create, log and send Bounce Delivery Status Notification.
     *
     * @param string $providerName Email provider name.
     * @param string $to           Recipient address.
     * @param string $from         Optional sender address.
     */
    public function __construct( $providerName, $to, $from = null ) {

        // Logging
        $this->logSetup();

        // Provider
        $providerClass = '\\Bouncedsn\\Provider\\' . ucfirst( $providerName ); #'
        if ( ! class_exists( $providerClass ) ) {
            Analog::alert( 'Non-existent provider.' );
            return;
        }

        // Mailing
        if ( ! filter_var( $to, FILTER_VALIDATE_EMAIL ) ) {
            Analog::alert( 'Invalid recipient address.' );
            return;
        }
        if ( empty( $from ) ) {
            $from = $to;
        }
        $mail          = new PHPMailer();
        $mail->CharSet = 'utf-8';
        $mail->XMailer = 'BounceDSN v' . $this->getVersion();
        $mail->setFrom( $from, ucfirst( $providerName ) . ' Bounce Notification' );
        $mail->addAddress( $to );

        // Instantiate provider class
        $provider = new $providerClass( file_get_contents( 'php://input' ), $mail );
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
        if ( $logPath = getenv( 'BOUNCE_DSN_LOG' ) ) {
            Analog::handler( File::init( $logPath ) );
            Analog::$date_format = '@U';
            Analog::$format = '%2$s|%3$d|%4$s' . "\n";

            return;
        }

        // Log to stderr
        Analog::handler( Stderr::init() );
        Analog::$format = 'Bounce DSN.%3$d: %4$s';
    }

    /**
     * Get package version from Composer
     */
    private function getVersion() {

        $composerFile = __DIR__ . '/../composer.json';
        if ( ! file_exists( $composerFile ) ) {

            return 'n/a';
        }
        $composerConfig = json_decode( file_get_contents( $composerFile ) );
        if ( false === $composerConfig || ! property_exists(  $composerConfig, 'version' ) ) {

            return 'unknown';
        }

        return $composerConfig->version;
    }
}
