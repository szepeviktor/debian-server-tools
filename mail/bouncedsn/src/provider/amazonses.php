<?php

namespace Bouncedsn\Provider;

use Analog\Analog;

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

    private $message_tpl = 'This is a MIME-formatted message.  If you see this text it means that your
E-mail software does not support MIME-formatted messages.

--=_amazonses_bounce_0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

This is a delivery status notification from Amazon SES.

The original message was received on %s
with recipient %s

Type %s, it is a %s failure.

--=_amazonses_bounce_0
Content-Type: message/delivery-status
Content-Transfer-Encoding: 7bit

X-Original-Message-Id: %s
Reporting-MTA: dns; %s
DSN-Gateway: dns; %s
Arrival-Date: %s

Original-Recipient: rfc822; %s
Final-Recipient: rfc822; %s
Action: failed
Remote-MTA: dns; %s
Status: %s
Diagnostic-Code: %s

--=_amazonses_bounce_0--
';

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
        if ( ! property_exists( $this->event, 'notificationType' )
            || 'Bounce' !== $this->event->notificationType
            || ! property_exists( $this->event, 'bounce' )
        ) {
            return false;
        }

        // Bounce message to be logged
        $bounce_msg = '';
        if ( in_array( $this->event->bounce->bounceType, array( 'Permanent', 'Transient' ) ) ) {
            $bounce_msg = sprintf( '%s bounce: %s',
                $this->event->bounce->bounceType,
                $this->event->bounce->bounceSubType
            );
        }

        // Generate log entry
        $output = array(
            '@' . $this->event->bounce->timestamp,
            $this->event->bounce->bouncedRecipients[0]->emailAddress,
            'bounce',
            $bounce_msg,
        );

        return implode( '|', $output );
    }

    private function construct_mail( $mail ) {

        $diag_elements = array(
            $this->event->bounce->bouncedRecipients[0]->diagnosticCode,
            'action=' . $this->event->bounce->bouncedRecipients[0]->action,
            'account=' . $this->event->mail->sendingAccountId,
            'subject=' . $this->event->mail->commonHeaders->subject,
        );
        $diag_code = $mail->encodeHeader( implode( '  ', $diag_elements ), 'quoted-printable' );
        $status    = $this->event->bounce->bouncedRecipients[0]->status;

        $mail->Subject = 'Delivery Status Notification (Failure)';

        // WARNING This is a PHPMailer hack
        $mail->ContentType = 'multipart/report; report-type=delivery-status; boundary="=_amazonses_bounce_0"';
        $mail->Body        = sprintf( $this->message_tpl,
            // The text/plain part for humans
            $this->ascii( date( 'r', strtotime( $this->event->mail->timestamp ) ) ),
            $this->ascii( $this->event->bounce->bouncedRecipients[0]->emailAddress ),
            $this->ascii( $this->event->bounce->bounceSubType ),
            $this->ascii( $this->event->bounce->bounceType ),
            // The message/delivery-status part
            // Per-Message DSN Fields
            $this->ascii( $this->event->mail->messageId ),
            $this->ascii( $this->event->bounce->reportingMTA ),
            $this->ascii( gethostname() ),
            $this->ascii( date( 'r', strtotime( $this->event->mail->timestamp ) ) ),
            // Per-Recipient DSN fields
            $this->ascii( $this->event->bounce->bouncedRecipients[0]->emailAddress ),
            $this->ascii( $this->event->bounce->bouncedRecipients[0]->emailAddress ),
            $this->ascii( $this->event->mail->sourceIp ),
            $status,
            $diag_code
        );
    }

    private function ascii( $string ) {

        return mb_convert_encoding( $string, 'ASCII' );
    }
}
