<?php

namespace Bouncedsn\Provider;

use PHPMailer\PHPMailer\PHPMailer;

/**
 * Log events and send bounce DSN.
 *
 * @link https://tools.ietf.org/html/rfc3464#section-2.2
 * @link https://www.iana.org/assignments/dsn-types/dsn-types.xhtml
 * @link https://www.mailjet.com/docs/event_tracking
 */
class Mailjet {

    private $event;

    private $message_tpl = 'This is a MIME-formatted message.  If you see this text it means that your
E-mail software does not support MIME-formatted messages.

--=_mailjet_bounce_0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit


This is a delivery status notification from Mailjet.

The original message was received on %s
with recipient %s

Remote server responded %s/%s, it is a %s failure.

--=_mailjet_bounce_0
Content-Type: message/delivery-status
Content-Transfer-Encoding: 7bit

Reporting-MTA: dns; mailjet.com
Arrival-Date: %s
Received-From-MTA: dns; in-v3.mailjet.com
X-Original-Message-ID: %s

Final-Recipient: rfc822; %s
Action: failed
Status: 5.0.0
Diagnostic-Code: smtp; %s/%s
        recipient blocked: %s
        permanent: %s
        campaign/contact: %s/%s

--=_mailjet_bounce_0--
';

    public function __construct( $bounce_json, $to, $from = '' ) {

        if ( empty( $bounce_json ) || ! filter_var( $to, FILTER_VALIDATE_EMAIL ) ) {
            error_log( 'Mailjet Event processing failed' );

            return;
        }

        if ( empty( $from ) ) {
            $from = $to;
        }

        $this->event = json_decode( trim( $bounce_json ) );

        $log_entry = $this->process_event();
        if ( false === $log_entry ) {
            error_log( 'Mailjet Event decoding failed: ' . serialize( $bounce_json ) );

            return;
        }

        if ( defined( 'MJ_LOG_FILE' ) && is_string( MJ_LOG_FILE ) ) {
            file_put_contents( MJ_LOG_FILE, $log_entry . "\n", FILE_APPEND | LOCK_EX );
        } else {
            error_log( 'Mailjet Event: ' . $log_entry );
        }

        if ( ! $this->send_mail( $from, $to ) ) {
            error_log( 'Mailjet DSN sending failed' );
        }
    }

    private function process_event() {

        // Invalid JSON or not an Event
        if ( ! is_object( $this->event ) || ! property_exists( $this->event, 'event' ) ) {

            return false;
        }

        // Bounce message
        $bounce_msg = '';
        if ( 'bounce' === $this->event->event ) {
            $bounce_msg = sprintf( '%s bounce: %s',
                ( 1 == $this->event->hard_bounce ) ? 'hard' : 'soft',
                $this->event->error
            );
        }

        // Generate log entry
        $output = array(
            '@' . $this->event->time,
            $this->event->email, // FIXME Available?
            $this->event->event,
            $bounce_msg,
        );

        return implode( '|', $output );
    }

    private function send_mail( $from, $to ) {

        $mail          = new PHPMailer();
        $mail->CharSet = 'utf-8';
        $mail->XMailer = 'BounceDSN ' . 'TODO:old';

        $mail->setFrom( $from, 'Mailjet Bounce Notification' );
        $mail->addAddress( $to );
        $mail->Subject = 'Delivery Status Notification (Failure)';

        $mail->ContentType = 'multipart/report; report-type=delivery-status; boundary="=_mailjet_bounce_0"';
        // @FIXME Add X-Mailjet-Campaign if $this->event->customcampaign
        $mail->Body = sprintf( $this->message_tpl,
            $this->ascii( date( 'r', $this->event->time ) ),
            $this->ascii( $this->event->email ),
            $this->ascii( $this->event->error_related_to ),
            $this->ascii( $this->event->error ),
            $this->ascii( $this->event->hard_bounce ) ? 'permanent' : 'temporary',
            $this->ascii( date( 'r', $this->event->time ) ),
            $this->ascii( $this->event->MessageID ),
            $this->ascii( $this->event->email ),
            $this->ascii( $this->event->error_related_to ),
            $this->ascii( $this->event->error ),
            $this->ascii( $this->event->blocked ? 'true' : 'false' ),
            $this->ascii( $this->event->hard_bounce ? 'true' : 'false' ),
            $this->ascii( $this->event->mj_campaign_id ),
            $this->ascii( $this->event->mj_contact_id )
        );

        return $mail->send();
    }

    private function ascii( $string ) {

        return mb_convert_encoding( $string, 'ASCII' );
    }
}
