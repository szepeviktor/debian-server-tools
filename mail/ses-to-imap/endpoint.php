<?php

define( 'SES_NOTIFICATIONS_PATH', '/home/USER/website/ses-sns-notifications' );
define( 'SES_S3_PATH', 's3://ses-DOMAINNAME/info/' );

require __DIR__ . '/vendor/autoload.php';

use Aws\Sns\Message;
use Aws\Sns\MessageValidator;
use Aws\Sns\Exception\InvalidSnsMessageException;

/**
 * Return response body for an URL as file_get_contents does.
 */
function curl_get_contents( $url ) {

    if ( ! function_exists( 'curl_init' ) ) {
        return false;
    }

    $ch      = curl_init();
    $timeout = 60;

    curl_setopt( $ch, CURLOPT_URL, $url );
    curl_setopt( $ch, CURLOPT_CONNECTTIMEOUT, $timeout );
    curl_setopt( $ch, CURLOPT_RETURNTRANSFER, true );
    $response = curl_exec( $ch );
    curl_close( $ch );

    return $response;
}

/**
 * Main program
 */
$message   = Message::fromRawPostData();
$validator = new MessageValidator( 'curl_get_contents' );

// Validate request
try {
    $validator->validate( $message );
} catch ( InvalidSnsMessageException $e ) {
    error_log( 'SNS Message Validation Error: ' . $e->getMessage() );
    // Pretend we're not here if the message is invalid
    http_response_code( 404 );
    die();
}

// Check the type of the message
switch ( $message['Type'] ) {
    case 'SubscriptionConfirmation':
        // Log SubscribeURL
        error_log( 'SubscribeURL: ' . $message['SubscribeURL'] );
        break;

    case 'Notification':
        // Handle the notification
        if ( ! isset( $message['Message'] ) ) {
            throw new \RuntimeException( 'Message is missing from SNS Notification.' );
        }

        // Get message data
        $message_data = json_decode( $message['Message'], true );
        if ( JSON_ERROR_NONE !== json_last_error() || ! is_array( $message_data ) ) {
            throw new \RuntimeException( 'Invalid SNS Message data.' );
        }

        // Process only the "Received" notification
        if ( isset( $message_data['notificationType'] ) && 'Received' === $message_data['notificationType'] ) {
            if ( empty( $message_data['mail']['messageId'] ) ) {
                throw new \RuntimeException( 'Missing SNS MessageID.' );
            }
            /* Old: .mail.destination[]
            if ( empty( $message_data['mail']['destination'] ) || ! is_array( $message_data['mail']['destination'] ) ) {
                throw new \RuntimeException( 'Missing SNS destination address.' );
            }
            $ses_address = $message_data['mail']['destination'][0];
            */
            if ( empty( $message_data['receipt']['recipients'] ) || ! is_array( $message_data['receipt']['recipients'] ) ) {
                throw new \RuntimeException( 'Missing SNS recipient address.' );
            }
            // Check action
            if ( empty( $message_data['receipt']['action']['type'] ) || 'S3' !== $message_data['receipt']['action']['type'] ) {
                throw new \RuntimeException( 'Message not saved to S3 bucket.' );
            }
            foreach ( $message_data['receipt']['recipients'] as $ses_address ) {
                // Log received message ID
                error_log( 'SNS Notification: Received ' . $message_data['mail']['messageId'] );
                // Append to a file on incron-watched path
                file_put_contents(
                    SES_NOTIFICATIONS_PATH . DIRECTORY_SEPARATOR . $ses_address,
                    // FIXME Get path Prefix from .receipt.action.objectKey instead of SES_S3_PATH
                    SES_S3_PATH . $message_data['mail']['messageId'] . "\n",
                    FILE_APPEND | LOCK_EX
                );
            }
        } else {
            // Dump unknown Notification
            $file = tempnam( ini_get( 'upload_tmp_dir' ), 'sns_unknown_' );
            file_put_contents( $file, var_export( $message_data, true ) );
        }
}
