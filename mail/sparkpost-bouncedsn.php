<?php

namespace Sparkpost;

use PHPMailer\PHPMailer\PHPMailer;

/**
 * Log events and send bounce DSN.
 *
 * Make sure:      mail.add_x_header PHP directive is turned Off
 * Dependency:     composer require phpmailer/phpmailer
 * Usage:          new \Sparkpost\BounceDsn( file_get_contents( 'php://input' ), 'postmaster@example.com', 'mailer-daemon@example.com' );
 * Custom logfile: define( 'SP_LOG_FILE', '/path/to/sparkpost.log' );
 *
 * @link https://tools.ietf.org/html/rfc3464#section-2.2
 * @link https://www.iana.org/assignments/dsn-types/dsn-types.xhtml
 * @link https://www.sparkpost.com/docs/tech-resources/webhook-event-reference/
 */
class BounceDsn {

    const VERSION = '0.1.0';

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
        25  => array( 'Admin Failure', 'The message was failed by SparkPost’s configured policies.', 'Admin' ),
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

    private $message_tpl = 'This is a MIME-formatted message.  If you see this text it means that your
E-mail software does not support MIME-formatted messages.

--=_sparkpost_bounce_0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

This is a delivery status notification from SparkPost.

The original message was received on %s
with recipient %s

%s It is a %s failure.

--=_sparkpost_bounce_0
Content-Type: message/delivery-status
Content-Transfer-Encoding: 7bit

Original-Envelope-Id: %s
X-Original-Message-Id: %s
Reporting-MTA: dns; %s
DSN-Gateway: dns; %s
Received-From-MTA: dns; smtp.sparkpostmail.com
Arrival-Date: %s

Original-Recipient: rfc822; %s
Final-Recipient: rfc822; %s
Action: failed
Remote-MTA: dns; %s
Status: %s
Diagnostic-Code: %s

--=_sparkpost_bounce_0--
';

    public function __construct( $bounce_json, $to, $from = '' ) {

        if ( empty( $bounce_json ) || ! filter_var( $to, FILTER_VALIDATE_EMAIL ) ) {
            error_log( 'SparkPost Event processing failed' );

            return false;
        }

        if ( empty( $from ) ) {
            $from = $to;
        }

        $events = json_decode( trim( $bounce_json ) );

        if ( ! is_array( $events ) ) {
            error_log( 'SparkPost Payload is incorrect: ' . serialize( $bounce_json ) );

            return false;
        }

        // Process all events
        foreach ( $events as $this->event ) {

            $log_entry = $this->process_event();

            if ( false === $log_entry ) {
                error_log( 'SparkPost Event decoding failed: ' . serialize( $this->event ) );
                continue;
            }

            $this->log( $log_entry );

            if ( ! $this->send_dsn( $from, $to ) ) {
                error_log( 'SparkPost DSN sending failed' );
            }
        }
    }

    private function log( $log_entry ) {

        if ( defined( 'SP_LOG_FILE' ) && is_string( SP_LOG_FILE ) ) {
            file_put_contents( SP_LOG_FILE, $log_entry . "\n", FILE_APPEND | LOCK_EX );
        } else {
            error_log( 'SparkPost Event: ' . $log_entry );
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
            if ( array_key_exists( $this->event->msys->message_event->bounce_class, $this->classification_codes ) ) {
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

    private function send_dsn( $from, $to ) {

        $event         = $this->event->msys->message_event;
        $mail          = new PHPMailer();
        $mail->XMailer = 'SparkPost Bounce Notification ' . self::VERSION;
        $diag_code     = $mail->encodeHeader( implode( "\r\n", array(
            'smtp; ' . $event->raw_reason,
            'customer=' . $event->customer_id,
            'retries=' . $event->num_retries,
            'from=' . $event->friendly_from,
            'subject=' . $event->subject,
            'size=' . $event->msg_size,
        ) ), 'quoted-printable' );
        $status        = '5.0.0';
        // Extract specific status from 'raw_reason'
        $status_match = array();
        if ( 1 === preg_match( '/^5\d\d (5\.\d\.\d) /', $event->raw_reason, $status_match ) ) {
            $status = $status_match[1];
        }

        $mail->setFrom( $from, 'SparkPost Bounce Notification' );
        $mail->addAddress( $to );
        $mail->Subject = 'Delivery Status Notification (Failure)';

        // WARNING This is a PHPMailer hack
        $mail->ContentType = 'multipart/report; report-type=delivery-status; boundary="=_sparkpost_bounce_0"';
        $mail->Body        = sprintf( $this->message_tpl,
            // The text/plain part for humans
            $this->ascii( date( 'r', strtotime( $event->injection_time ) ) ),
            $this->ascii( $event->raw_rcpt_to ),
            $this->ascii( $this->classification_code[1] ),
            ( 'Soft' === $this->classification_code[2] ) ? 'temporary' : 'permanent',
            // The message/delivery-status part
            // Per-Message DSN Fields
            $this->ascii( $event->transmission_id ),
            $this->ascii( $event->message_id ),
            $this->ascii( $event->sending_ip ),
            $this->ascii( gethostname() ),
            $this->ascii( date( 'r', $event->timestamp ) ),
            // Per-Recipient DSN fields
            $this->ascii( $event->raw_rcpt_to ),
            $this->ascii( $event->raw_rcpt_to ),
            $this->ascii( $event->ip_address ),
            $status,
            $diag_code
        );

        return $mail->send();
    }

    private function ascii( $string ) {

        return mb_convert_encoding( $string, 'ASCII' );
    }
}
