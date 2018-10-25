<?php

namespace Bouncedsn\Provider;

use Analog\Analog;
use Twig\Loader\FilesystemLoader;
use Twig\Environment;

/**
 * Process Amazon SES events.
 *
 * @link https://tools.ietf.org/html/rfc3464#section-2.2
 * @link https://www.iana.org/assignments/dsn-types/dsn-types.xhtml
 * @link https://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html
 */
class Amazonses {

    /**
     * Success of event processing
     */
    public $processing = true;

    /**
     * One event
     */
    private $event;

    /**
     * A notification
     */
    private $message;

    public function __construct( $bounce_json, $mail ) {

        $this->event = json_decode( trim( $bounce_json ) );

        if ( ! is_object( $this->event ) ) {
            Analog::error( 'Amazon SES Payload is incorrect: ' . serialize( $bounce_json ) );
            $this->processing = false;

            return;
        }

        // Handle subscription
        if ( property_exists( $this->event, 'SubscribeURL' ) ) {
            Analog::info( 'Amazon SES Subscribe URL: ' . $this->event->SubscribeURL );
            $this->processing = false;

            return;
        }

        // Process event
        $log_entry = $this->process_event();

        if ( false === $log_entry ) {
            Analog::error( 'Amazon SES Event decoding failed: ' . serialize( $this->event ) );
            $this->processing = false;

            return;
        }

        Analog::info( $log_entry );

        $this->construct_mail( $mail );
    }

    private function process_event() {

        // Not a Bounce Notification
        if ( 'Notification' !== $this->event->Type ) {
            return false;
        }
        $this->message = json_decode( $this->event->Message );
        if ( ! is_object( $this->message ) ) {
            return false;
        }
        if ( ! property_exists( $this->message, 'notificationType' )
            || 'Bounce' !== $this->message->notificationType
            || ! property_exists( $this->message, 'bounce' )
        ) {
            return false;
        }

        // Bounce message to be logged
        $bounce_msg = '';
        if ( in_array( $this->message->bounce->bounceType, array( 'Permanent', 'Transient' ) ) ) {
            $bounce_msg = sprintf( '%s bounce: %s',
                $this->message->bounce->bounceType,
                $this->message->bounce->bounceSubType
            );
        }

        // Generate log entry
        $output = array(
            '@' . $this->message->bounce->timestamp,
            $this->message->bounce->bouncedRecipients[0]->emailAddress,
            'bounce',
            $bounce_msg,
        );

        return implode( '|', $output );
    }

    private function construct_mail( $mail ) {

        $diag_elements = array(
            $this->message->bounce->bouncedRecipients[0]->diagnosticCode,
            'action=' . $this->message->bounce->bouncedRecipients[0]->action,
            'account=' . $this->message->mail->sendingAccountId,
            'subject=' . $this->message->mail->commonHeaders->subject,
        );
        $diag_code = $mail->encodeHeader( implode( '  ', $diag_elements ), 'quoted-printable' );
        $status    = $this->message->bounce->bouncedRecipients[0]->status;

        $twigLoader = new FilesystemLoader( __DIR__ . '/../template' );
        $twig       = new Environment( $twigLoader );
        // Have HTML escaping use ascii()
        $twig->getExtension( 'Twig_Extension_Core' )->setEscaper( 'html', array( $this, 'ascii' ) );

        $mail->Subject = 'Delivery Status Notification (Failure)';
        // WARNING This is a PHPMailer hack
        $mail->ContentType = 'multipart/report; report-type=delivery-status; boundary="=_amazonses_bounce_0"';
        $templateVars      = array(
            // The text/plain part for humans
            'timestamp_original' => date( 'r', strtotime( $this->message->mail->timestamp ) ),
            'recipient'          => $this->message->bounce->bouncedRecipients[0]->emailAddress,
            'class_desc'         => $this->message->bounce->bounceSubType,
            'class_type'         => $this->message->bounce->bounceType,
            // The message/delivery-status part
            // Per-Message DSN Fields
            'message_id'         => $this->message->mail->messageId,
            'sending_ip'         => $this->message->bounce->reportingMTA,
            'hostname'           => gethostname(),
            'timestamp_arrival'  => date( 'r', strtotime( $this->message->mail->timestamp ) ),
            // Per-Recipient DSN Fields
            'status'             => $status,
            'diag_code'          => $diag_code,
        );
        // Add custom headers
        $xHeaders = array();
        foreach ( $this->message->mail->headers as $header ) {
            if ( substr( $header->name, 0, 2 ) !== 'X-' ) {
                continue;
            }
            $xHeaders[] = $header;
        }
        $templateVars['x_headers'] = $xHeaders;
        $mail->Body                = $twig->render( 'amazonses-dsn.eml', $templateVars );
    }

    public function ascii( $string ) {

        return mb_convert_encoding( $string, 'ASCII' );
    }
}
