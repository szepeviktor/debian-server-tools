<?php

namespace Bouncedsn\Provider;

use Analog\Analog;
use Twig\Loader\FilesystemLoader;
use Twig\Environment;

/**
 * Process SparkPost events.
 *
 * @link https://tools.ietf.org/html/rfc3464#section-2.2
 * @link https://www.iana.org/assignments/dsn-types/dsn-types.xhtml
 * @link https://www.sparkpost.com/docs/tech-resources/webhook-event-reference/
 */
class Sparkpost {

    /**
     * Success of event processing
     */
    public $processing = true;

    /**
     * One event
     */
    private $event;

    /**
     * Events handled by this class
     */
    private $event_types = array( 'bounce', 'spam_complaint', 'out_of_band', 'policy_rejection' );

    /**
     * Default classification data
     */
    private $classification_code = array( 'Spam Complaint', 'Message was classified as spam by the recipient.', 'Spam' );

    /**
     * Known classification codes in 'bounce_class'
     *
     * Classification => Name, Description, Category
     */
    private $classification_codes = array(
        1   => array( 'Undetermined', 'The response text could not be identified.', 'Undetermined' ),
        10  => array( 'Invalid Recipient', 'The recipient is invalid.', 'Hard' ),
        20  => array( 'Soft Bounce', 'The message soft bounced.', 'Soft' ),
        21  => array( 'DNS Failure', 'The message bounced due to a DNS failure.', 'Soft' ),
        22  => array( 'Mailbox Full', 'The message bounced due to the remote mailbox being over quota.', 'Soft' ),
        23  => array( 'Too Large', 'The message bounced because it was too large for the recipient.', 'Soft' ),
        24  => array( 'Timeout', 'The message timed out.', 'Soft' ),
        25  => array( 'Admin Failure', "The message was failed by SparkPost's configured policies.", 'Admin' ),
        26  => array( 'Smart Send Suppression', 'The message was suppressed by Smart Send policy.', 'Admin' ),
        30  => array( 'Generic Bounce: No RCPT', 'No recipient could be determined for the message.', 'Hard' ),
        40  => array( 'Generic Bounce', 'The message failed for unspecified reasons.', 'Soft' ),
        50  => array( 'Mail Block', 'The message was blocked by the receiver.', 'Block' ),
        51  => array( 'Spam Block', 'The message was blocked by the receiver as coming from a known spam source.', 'Block' ),
        52  => array( 'Spam Content', 'The message was blocked by the receiver as spam.', 'Block' ),
        53  => array( 'Prohibited Attachment', 'The message was blocked by the receiver because it contained an attachment.', 'Block' ),
        54  => array( 'Relaying Denied', 'The message was blocked by the receiver because relaying is not allowed.', 'Block' ),
        60  => array( 'Auto-Reply', 'The message is an auto-reply/vacation mail.', 'Soft' ),
        70  => array( 'Transient Failure', 'Message transmission has been temporarily delayed.', 'Soft' ),
        80  => array( 'Subscribe', 'The message is a subscribe request.', 'Admin' ),
        90  => array( 'Unsubscribe', 'The message is an unsubscribe request.', 'Hard' ),
        100 => array( 'Challenge-Response', 'The message is a challenge-response probe.', 'Soft' ),
    );

    public function __construct( $bounce_json, $mail ) {

        $events = json_decode( trim( $bounce_json ) );

        if ( ! is_array( $events ) ) {
            Analog::error( 'SparkPost Payload is incorrect: ' . serialize( $bounce_json ) );

            $this->processing = false;
            return;
        }

        // Process all events
        foreach ( $events as $this->event ) {

            $log_entry = $this->process_event();

            if ( false === $log_entry ) {
                Analog::error( 'SparkPost Event decoding failed: ' . serialize( $this->event ) );
                continue;
            }

            Analog::info( $log_entry );

            $this->construct_mail( $mail );
        }
    }

    private function process_event() {

        // Invalid JSON or not a Message Event
        if ( ! is_object( $this->event )
            // Why "msys"? https://www.sparkpost.com/messagesystems-momentum/
            || ! property_exists( $this->event, 'msys' )
            || ! property_exists( $this->event->msys, 'message_event' )
        ) {

            return false;
        }

        // Bounce message to be logged
        $bounce_msg = '';
        if ( in_array( $this->event->msys->message_event->type, $this->event_types ) ) {
            // Classify
            if ( property_exists( $this->event->msys->message_event, 'bounce_class' )
                && array_key_exists( $this->event->msys->message_event->bounce_class, $this->classification_codes )
            ) {
                $this->classification_code = $this->classification_codes[ $this->event->msys->message_event->bounce_class ];
            }
            $bounce_msg = sprintf( '%s bounce: %s', $this->classification_code[2], $this->classification_code[0] );
        }

        // Generate log entry
        $output = array(
            '@' . $this->event->msys->message_event->timestamp,
            $this->event->msys->message_event->raw_rcpt_to,
            'bounce',
            $bounce_msg,
        );

        return implode( '|', $output );
    }

    private function construct_mail( $mail ) {

        $event = $this->event->msys->message_event;
        // Bounce notification or spam complaint
        $event->raw_reason = property_exists( $event, 'raw_reason' ) ? $event->raw_reason : $event->report_by;
        // Decode with for example https://dogmamix.com/MimeHeadersDecoder/
        $diagElements = array(
            'smtp; ' . $event->raw_reason,
            'type=' . $event->type,
            'customer=' . $event->customer_id,
        );
        // Optional details
        if ( property_exists( $event, 'num_retries' ) ) {
            $diagElements[] = 'retries=' . $event->num_retries;
        }
        if ( property_exists( $event, 'friendly_from' ) ) {
            $diagElements[] = 'from=' . $event->friendly_from;
        }
        if ( property_exists( $event, 'subject' ) ) {
            $diagElements[] = 'subject=' . $event->subject;
        }
        if ( property_exists( $event, 'msg_size' ) ) {
            $diagElements[] = 'size=' . $event->msg_size;
        }
        $diag_code = $mail->encodeHeader( implode( '  ', $diagElements ), 'quoted-printable' );
        $status    = '5.0.0';
        // Extract specific status from 'raw_reason'
        $status_match = array();
        if ( 1 === preg_match( '/^5\d\d (5\.\d\.\d) /', $event->raw_reason, $status_match ) ) {
            $status = $status_match[1];
        }

        $twigLoader = new FilesystemLoader( __DIR__ . '/../template' );
        $twig       = new Environment( $twigLoader );
        // Have HTML escaping use ascii()
        $twig->getExtension( 'Twig_Extension_Core' )->setEscaper( 'html', array( $this, 'ascii' ) );

        $mail->Subject = 'Delivery Status Notification (Failure)';
        // WARNING This is a PHPMailer hack
        $mail->ContentType = 'multipart/report; report-type=delivery-status; boundary="=_sparkpost_bounce_0"';
        $templateVars      = array(
            // The text/plain part for humans
            'timestamp_original' => date( 'r', strtotime( $event->injection_time ) ),
            'recipient'          => $event->raw_rcpt_to,
            'class_desc'         => $this->classification_code[1],
            'class_type'         => ( 'Soft' === $this->classification_code[2] ) ? 'temporary' : 'permanent',
            // The message/delivery-status part
            // Per-Message DSN Fields
            'transmission_id'    => $event->transmission_id,
            'message_id'         => $event->message_id,
            'sending_ip'         => $event->sending_ip,
            'hostname'           => gethostname(),
            'timestamp_arrival'  => date( 'r', $event->timestamp ),
            // Per-Recipient DSN Fields
            'status'             => $status,
            'diag_code'          => $diag_code,
        );
        if ( property_exists( $event, 'ip_address' ) ) {
            $templateVars[] = $event->ip_address;
        }
        $mail->Body = $twig->render( 'sparkpost-dsn.eml', $templateVars );
    }

    public function ascii( $string ) {

        return mb_convert_encoding( $string, 'ASCII' );
    }
}
