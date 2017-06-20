# WordPress website lifecycle

## Where do I find ...?

- Development environment: [/webserver/WP-config-dev.md](/webserver/WP-config-dev.md)
- Development tools: wordpress-sitebuild/
- Production environment: [/webserver/Production-website.md](/webserver/Production-website.md)
- Production on cPanel and migration to cPanel: [wordpress-plugin-construction/shared-hosting-aid/cPanel/README.md](https://github.com/szepeviktor/wordpress-plugin-construction/blob/master/shared-hosting-aid/cPanel/README.md)
- Content plugins: [wordpress-plugin-construction/README.md](https://github.com/szepeviktor/wordpress-plugin-construction/blob/master/README.md)
- WordPress installation: standard, subdirectory (optionally using git) [in this document](#standard-directory-structure)
- WordPress imigration: dev->live, live->other domain [/webserver/Production-website.md](/webserver/Production-website.md#migration)


### Standard Directory structure

```
wp-cli.yml
wp-config.php
DOCROOT/─┬─index.php
         ├─wp-load.php
         ├─wp-login.php
         ├─xmlrpc.php
         ├─wp-admin/
         ├─wp-includes/
         └─wp-content/
```


### Subdirectory structure

```
wp-cli.yml
DOCROOT/─┬─index.php (modified)
         ├─wp-config.php
         ├─wp-login.php (trap)
         ├─xmlrpc.php (trap)
         ├─CORE/─┬─index.php
         │       ├─wp-load.php
         │       ├─wp-login.php
         │       ├─wp-admin/
         │       └─wp-includes/
         └─static/ (wp-content)
```


### Installation by WP-CLI

`wp-cli.yml`

```yaml
path: $WPROOT
url: $WPHOMEURL
debug: true
user: viktor
core update:
    locale: hu_HU
skip-plugins:
    # Version randomizer
    - better-wp-security
```

```bash
# Existing database
./wp-createdb.sh

# New installation
wp core download --locale=hu_HU
wp core config --dbname="$DBNAME" --dbuser="$DBUSER" --dbpass="$DBPASS" \
    --dbhost="$DBHOST" --dbprefix="prod" --dbcharset="$DBCHARSET" --extra-php <<EOF
// Extra PHP code
EOF
wp core install --title="WP" --admin_user="viktor" --admin_email="viktor@szepe.net" --admin_password="12345"

wp option set home "$WPHOMEURL"
wp option set blog_public "0"
wp option set admin_email "support@company.net"
```

@TODO Move to wp-lib

### Remove default content

```bash
wp post delete $(wp post list --name="$(wp eval 'echo sanitize_title( _x( "hello-world", "Default post slug" ) );')" --posts_per_page=1 --format=ids)
wp post delete $(wp post list --post_type=page --name="$(wp eval 'echo __( "sample-page" );')" --posts_per_page=1 --format=ids)
wp comment delete 1
wp option update blogdescription ""
wp plugin uninstall akismet
wp plugin uninstall hello-dolly
wp theme delete twentyfifteen
wp theme delete twentyfourteen
```

### Use child theme

Purchased themes can be updated using a child theme.

```bash
wp plugin install child-theme-configurator --activate
```

Keep changes in git.

### Redis object cache

[Free 30 MB Redis instance by redislab](https://redislabs.com/redis-cloud)


### Development

See /webserver/Wp-config-dev.md


### Plugins

#### Core

```bash
mkdir wp-content/mu-plugins/

# InnoDB table engine
wget -qO- https://github.com/szepeviktor/debian-server-tools/raw/master/mysql/alter-table.sql \
 | mysql -N $(cd public_html/;wp eval 'echo DB_NAME;') | mysql

# disable updates
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-disable-updates/disable-updates.php

# disable comments
wget -P wp-content/mu-plugins/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu.php
wget -P wp-content/mu-plugins/disable-comments-mu/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu/comments-template.php

# smilies
wp plugin install classic-smilies --activate

# mail
wp plugin install wp-mailfrom-ii smtp-uri --activate
#wget -P wp-content/mu-plugins/ https://github.com/danielbachhuber/mandrill-wp-mail/raw/master/mandrill-wp-mail.php
wp eval 'var_dump(wp_mail("admin@szepe.net","First outgoing",site_url()));'
# define( 'SMTP_URI', 'smtp://FOR-THE-WEBSITE%40DOMAIN.TLD:PWD@localhost' );

# multilanguage
wp plugin install polylang --activate
```

#### Security

```bash
# users/login

wp plugin install password-bcrypt
cp wp-content/plugins/password-bcrypt/wp-password-bcrypt.php wp-content/mu-plugins/
wp plugin uninstall password-bcrypt
wp plugin install user-session-control --activate
# user role editor
wp plugin install user-role-editor --activate
# keepass-button
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-keepass-button/keepass-button.php

# Fail2ban Wordpress
wget https://github.com/szepeviktor/wordpress-fail2ban/raw/master/block-bad-requests/wp-fail2ban-bad-request-instant.inc.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-fail2ban/raw/master/mu-plugin/wp-fail2ban-mu-instant.php

# security suite + audit

wp plugin install custom-sucuri sucuri-scanner --activate
# audit
wp plugin install wp-user-activity --activate
# simple audit
wp plugin install simple-history --activate

# prevent spam

wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-nofollow-robot-trap/nofollow-robot-trap.php
# Installation: https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/mu-nofollow-robot-trap
wget -P wp-content/plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/contact-form-7-robot-trap/cf7-robot_trap.php
wp plugin install obfuscate-email --activate
```

#### Forcing

```bash
# mu-lock-session-ip
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-lock-session-ip/lock-session-ip.php

# prevent-concurrent-logins
wp plugin install prevent-concurrent-logins --activate

# mu-disallow-weak-passwords
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-disallow-weak-passwords/disallow-weak-passwords.php

# mu-banned-email-addresses
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-banned-email-addresses/banned-email-addresses.php

# media
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-image-upload-control/image-upload-control.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-image-upload-control/image-upload-control-hu.php

# protect plugins
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-protect-plugins/protect-plugins.php
```

#### Object cache

```php
// WP_CACHE_KEY_SALT in wp-config.php
$redis_server = array(
    'host' => '127.0.0.1',
    'port' => 6379,
);
```

```bash
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-cache-flush-button/flush-cache-button.php

# Redis @danielbachhuber
wp transient delete-all
wp plugin install wp-redis --activate
wp redis enable

# Memcached @Automattic
wget -P wp-content/ https://github.com/Automattic/wp-memcached/raw/master/object-cache.php
wp transient delete-all

# APCu
# WARNING! APCu is not available from CLI by default during WP-Cron/WP-CLI
wget -P wp-content/ https://github.com/l3rady/WordPress-APCu-Object-Cache/raw/master/object-cache.php
wp transient delete-all
# Worse plugin: wp plugin install apcu
```


#### Optimize HTML + HTTP

Resource optimization

```bash
# resource-versioning
wp plugin install resource-versioning --activate

# CDN, Page Cache, Minify
wp plugin install w3-total-cache --activate
wp plugin install https://github.com/szepeviktor/fix-w3tc/releases/download/v0.9.4.2/w3-total-cache.0.9.4.2.zip --activate

# minit
wp plugin install https://github.com/kasparsd/minit/archive/master.zip
wp plugin install https://github.com/markoheijnen/Minit-Pro/archive/master.zip

# safe redirect manager
wp plugin install safe-redirect-manager --activate

# WP-FFPC
# backends: APCu, Memcached with ngx_http_memcached_module
# https://github.com/petermolnar/wp-ffpc
wp plugin install https://github.com/petermolnar/wp-ffpc/archive/master.zip --activate

## Autoptimize - CONFLICTS with resource-versioning
#wp plugin install autoptimize --activate
#     define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );
```

Set up CDN.


#### Plugin fixes

MU Plugin Template

`disable-3rd-party-updates.php`

```php
<?php
/*
Plugin Name: disable custom updates (MU)
Version: 0.0.0
Description: This MU plugin contains hooks to disable custom updates.
Plugin URI: https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/WordPress.md#plugin-fixes
Author: Viktor Szépe
*/
```

Revolution Slider plugin security fix

```php
/*
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
```

TGM Plugin Activation

```php
// Disable TGMPA (procedural)
add_action( 'after_setup_theme', function () {
    remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
    remove_action( 'tgmpa_register', 'CUSTOM-FUNCTION' );
}, 9999 );

// Disable TGMPA (OOP)
add_action( 'after_setup_theme', function () {
    global $wpoEngine;
    if ( method_exists( $wpoEngine, 'initRequiredPlugin' ) ) {
        remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
        remove_action( 'tgmpa_register', array( $wpoEngine, 'initRequiredPlugin' ) );
    }
}, 9999 );
```

WPBakery Visual Composer plugin

```php
// Disable VC updates
add_action( 'plugins_loaded', function () {
    global $vc_manager;
    if ( method_exists( $vc_manager, 'disableUpdater' ) ) {
        $vc_manager->disableUpdater( true );
        add_filter( 'pre_option_wpb_js_js_composer_purchase_code', '__return_true' );
    }
} );
```

Easy Social Share Buttons plugin

```php
// Disable ESSB updates
add_action( 'plugins_loaded', function () {
    global $essb_manager;
    if ( method_exists( $essb_manager, 'disableUpdater' ) ) {
        $essb_manager->disableUpdates( true );
    }
} );
```

Envato Market plugin for ThemeForest updates

```bash
wp plugin install https://envato.github.io/wp-envato-market/dist/envato-market.zip --activate
```

`envato-market-update.sh`

```bash
#!/bin/bash

WP_CONTENT_DIR="$(wp --no-debug eval 'echo WP_CONTENT_DIR;')"

if [ -n "$WP_CONTENT_DIR" ] && [ -d "$WP_CONTENT_DIR" ]; then
    wp --no-debug plugin install "https://github.com/envato/wp-envato-market/archive/master.zip" --force
fi
```

Gravity Forms plugin

```php
// Disable Gravity Forms updates
define( 'GRAVITY_MANAGER_URL', null );
define( 'GRAVITY_MANAGER_PROXY_URL', null );
add_filter( 'pre_transient_gform_update_info', '__return_true' );
add_filter( 'option_gform_enable_background_updates', '__return_false' );
```

Unity theme

`external-plugin-update.sh`

```bash
#!/bin/bash

CURRENT="$(dirname "$0")/external-plugin-update.log"

# From wp-content/themes/unity/inc/frontend.php
EXTERNAL_PLUGINS=(
    http://www.wpopal.com/thememods/appthemer-crowdfunding.zip
    http://www.wpopal.com/thememods/js_composer.zip
    http://www.wpopal.com/thememods/revslider.zip
)

for PLUGIN in ${EXTERNAL_PLUGINS[@]}; do
    wget -q --spider -S "$PLUGIN" 2>&1 | grep -F "Last-Modified:"
done | diff "$CURRENT" -

#exit 0
```

### On deploy and Staging->Production Migration

@TODO Move to Production-website.md

Also in /webserver/Production-website.md

- `wp transient delete-all`
- `wp db query "DELETE FROM $(wp eval 'global $table_prefix;echo $table_prefix;')options WHERE option_name LIKE '%_transient_%'"`
- Remove development wp_options -> Option Inspector
- Delete unused Media files @TODO `for $m in files; search $m in DB;`
- `wp db optimize`
- WP Cleanup


#### Settings

- General Settings
- Writing Settings
- Reading Settings
- Media Settings
- Permalink Settings
- WP Mail From


#### Search & replace items

```bash
wp search-replace --precise --recurse-objects --all-tables-with-prefix ...
wp search-replace --precise --recurse-objects --all-tables-with-prefix ...
wp search-replace --precise --recurse-objects --all-tables-with-prefix ...
wp search-replace --precise --recurse-objects --all-tables-with-prefix ...
```

1. http://DOMAIN.TLD or https (no trailing slash)
1. /home/PATH/TO/SITE (no trailing slash)
1. EMAIL@ADDRESS.ES (all addresses)
1. DOMAIN.TLD (now without http)

Manually replace constants in `wp-config.php`


### Moving a site to a subdirectory

1. siteurl += /site
1. search-and-replace: /wp-includes/ -> /site/wp-includes/
1. search-and-replace: /wp-content/ -> /static/

S&R links...

### Signature

```bash
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-sitebuild/raw/master/theme-development/Signature.php
```
