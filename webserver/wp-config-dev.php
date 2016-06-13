<?php

// See also: wp-config-live-debug.php

// PHP-FPM pool config: env[WP_ENV] = development

// WP_ENV by roots.io  https://github.com/roots/wp-stage-switcher/blob/master/wp-stage-switcher.php
// Values: production, staging, development
define( 'WP_ENV', ( getenv( 'WP_ENV' ) ? : 'development' ) );

/** Development */
if ( defined( 'WP_ENV' ) && 'development' === WP_ENV ) {
    // WP_LOCAL_DEV by Mark Jaquith  https://gist.github.com/markjaquith/1044546
    define( 'WP_LOCAL_DEV', true );

    // WARNING! Lazy dev site - Links and images in posts are still pointing to the production site.
    define( '_REQUEST_SCHEME', ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) ? 'https://' : 'http://' );
    // EDIT core directory
    define( 'WP_SITEURL', sprintf( '%s%s/wordpress', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_HOME', _REQUEST_SCHEME . $_SERVER['HTTP_HOST'] );
    // EDIT wp-content directory
    define( 'WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/static' );
    // EDIT wp-content directory
    define( 'WP_CONTENT_URL', sprintf( '%s%s/static', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_DEBUG', true );
    define( 'WP_CACHE', false );
}

/*

    This is a @TODO list for a MU plugin.

// EDIT production domain name
if ( 'production.com' !== $_SERVER['SERVER_NAME'] ) {
    exit( 'Environment failure: no production on this domain!' );
}

1. Create /robots.txt
1. WordPress development constants
      https://codex.wordpress.org/Editing_wp-config.php
      define('SAVEQUERIES', false);define('JETPACK_DEV_DEBUG', true);
1. Salts: change
1. CDN: disable
1. Plugins: disable plugins, require plugins (must be enabled)
      mu-prevent-public
      mu-no-mail
      error-log-monitor
      plugin-installer-speedup
      manual-cron
      option-inspector
      what-the-file
      query-monitor (off)
1. HTTP traffic: airplanemode, analytics, other 3rd-party service:newrelic, mouse tracking (admin and frontend)
1. Mail:
    1. sendmail block: php_admin_value[disable_functions] += mail
    1. sendmail hijack: php_admin_value[sendmail_path] = /usr/local/sbin/dev-sendmail.sh
    1. sendmail hijack: error_log? sendmail_path = sudo -u pool_user -- php -r "error_log('sendmail: $data');"
    1. sendmail hijack: force recipient? sendmail_path = /usr/sbin/sendmail -f fpm-pool@domain.tld fixed@recipient.net
    1. SMTP block: Block OUTPUT to tcp port 25, 587, 465
    1. SMTP hijack: FORWARD by uid-owner dev.smtp.com, Mailcatcher, MailHog
1. Visuals: admin bar (outline-bottom+transition), page title (admin and frontend)
      https://plugins.svn.wordpress.org/easy-local-site/trunk/easy-local-site.php
1. Enable developer's user as administrator
1. Small how-to for the developer

Development environment
-----------------------
- Doc: dev vhost+pool
- FPM pool: ondemand
- Fail2ban?
- Http/auth?

sendmail.sh
#!/bin/dash
#
# Dump email to a file.
#
# LOCATION      :/usr/local/sbin/dev-sendmail.sh

# Must be world writable or use SUID
DUMP_PATH="/tmp"

{
    echo "X-Sendmail-Args: $*"
    cat
} > "${DUMP_PATH}/$(/bin/date "+%F_%H.%M.%S.%N_%z").eml"

*/
