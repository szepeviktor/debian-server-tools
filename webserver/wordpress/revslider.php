<?php

/**
 * Trigger fail2ban on Revolution Slider upload attempt.
 *
 * revslider/revslider_admin.php:389
 *
 *     case "update_plugin":
 *
 *     // self::updatePlugin(self::DEFAULT_VIEW);
 *
 * Patched in version 4.2
 */
error_log( 'Break-in attempt detected: ' . 'revslider_update_plugin' );
exit;
