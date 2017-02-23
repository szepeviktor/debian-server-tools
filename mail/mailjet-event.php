<?php
/**
 * Mailjet Event API Endpoint Handler
 */

define( 'MJ_LOG_FILE', dirname( __DIR__ ) . '/mailjet-bounces.log' );

function mj_event_process( $post_raw ) {

    $mj_event = json_decode( trim( $post_raw ) );

    // Invalid JSON or not an event
    if ( null === $mj_event || ! is_object( $mj_event ) || ! property_exists( $mj_event, 'event' ) ) {
        error_log( 'MJ-event:' . serialize( $post_raw ) );
        return false;
    }

    // Prepare bounce message
    $bounce_msg = '';
    if ( 'bounce' === $mj_event->event ) {
        $bounce_msg = sprintf( '%s/%s',
            ( $mj_event->hard_bounce == 1 ) ? 'hard' : 'soft',
            $mj_event->error
        );
    }
    // Append to log
    $output = array(
        '@' . $mj_event->time,
        $mj_event->event,
        $mj_event->email,
        $bounce_msg,
    );
    file_put_contents( MJ_LOG_FILE, implode( "\t", $output ) . "\n", FILE_APPEND );
}

mj_event_process( file_get_contents( 'php://input' ) );
