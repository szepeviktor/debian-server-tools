# WordPress website lifecycle

## Where do I find ...?

- Development environment: [/webserver/WP-config-dev.md](/webserver/WP-config-dev.md)
- Development tools: `szepeviktor/wordpress-sitebuild` repo
- Production environment: [/webserver/Production-website.md](/webserver/Production-website.md)
- Production on cPanel and migration to cPanel: [shared-hosting-aid/cPanel/README.md](https://github.com/szepeviktor/shared-hosting-aid/blob/master/cPanel/README.md)
- Content plugins: [wordpress-plugin-construction/README.md](https://github.com/szepeviktor/wordpress-plugin-construction/blob/master/README.md)
- WordPress installation: standard, subdirectory (optionally using git) [in this document](#standard-directory-structure)
- WordPress migration: dev->live, live->other domain [/webserver/Production-website.md](/webserver/Production-website.md#migration)


### Onboarding for developers

Let's prevent working against each other!

- Don't write code changing WordPress core behavior anywhere else than **MU plugins**,
  all these are part of [our proactive WordPress installation](/webserver/WordPress.md)
  - removing admin menus, admin bar elements
  - disabling emojis
  - disabling comments
  - disabling feeds
  - disabling embeds
  - mail settings and logging
  - WAF: authentication/login, HTTP and REST API security
  - comment form and contact form spam traps
  - media management
  - nav menu, translation and content caching
  - HTTP and HTML optimization
  - CDN support
- Plugin update check HTTP requests and updates itself are disabled
  because the whole WordPress installation is **managed by Composer**
- Plugin and theme update and WordPress management-related admin pages are removed
  (updated with Composer, administered with WP-CLI)
- WP-Cron is ran by a linux cron job (the default pseudo cron/web callback is disabled)
- Only things necessary for generating custom admin pages
  and generating HTML go into the **theme**
- Business logic (e.g. processing input from visitors) goes into **plugins**
- Please adhere to a coding standard of **your choice**
- Please avoid [discouraged functions](/webserver/laravel/phpcs.xml)
- We run static analysis on all source code
- PSR-4 autoloading is suggested (no need for `require` and custom class autoloading)
- WordPress core is installed in a separate subdirectory
- Please also see [hosting information for developers](/Onboarding.md#onboarding-for-developers)

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

### Semisecret Subdirectory structure

```
composer.json
composer.lock
vendor/
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
         └─wp-content/
```

The value of `CORE` may be the abbreviation of the project.

`wp-content` can be renamed.

##### Where script kiddies look for WordPress

- /backup/
- /blog/
- /cms/
- /demo/
- /dev/
- /home/
- /main/
- /new/
- /old/
- /portal/
- /site/
- /test/
- /tmp/
- /web/
- /wordpress/
- /wp/

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
wp option set blog_public 0
wp option set admin_email "webmaster@example.com"
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
wp theme install page-builder-framework --activate
wp plugin install child-theme-configurator --activate
```

Keep changes in git.

### [Plugins](https://plugintests.com/search-ids)

#### For core

```bash
export WPSZV="https://github.com/szepeviktor/wordpress-plugin-construction/raw/master"
mkdir wp-content/mu-plugins/

# InnoDB table engine
wget -qO- https://github.com/szepeviktor/debian-server-tools/raw/master/mysql/alter-table.sql \
 | mysql -N $(wp eval 'echo DB_NAME;') | mysql

# no parent themes
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/debian-server-tools/raw/master/webserver/wordpress/_core-themes.php

# disable updates
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-disable-updates/disable-updates.php

# disable comments
wget -P wp-content/mu-plugins/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu.php
wget -P wp-content/mu-plugins/disable-comments-mu/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu/comments-template.php

# disable feeds
#wp plugin install disable-feeds --activate

# disable embeds
#wp plugin install disable-embeds --activate

# smilies
wp plugin install classic-smilies --activate

# multilanguage
wp plugin install polylang --activate

# mail
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/debian-server-tools/raw/master/webserver/wordpress/_core-mail.php
#wp plugin install wp-mailfrom-ii smtp-uri --activate
# define( 'SMTP_URI', 'smtp://FOR-THE-WEBSITE%40DOMAIN.TLD:PWD@localhost' );
wp plugin install wp-mailfrom-ii --activate
#wget -P wp-content/mu-plugins/ https://github.com/danielbachhuber/mandrill-wp-mail/raw/master/mandrill-wp-mail.php
wp eval 'var_dump(wp_mail("admin@szepe.net","First outgoing",site_url()));'
```

#### Security

```bash
# users/login

#wp plugin install password-bcrypt
#cp -v wp-content/plugins/password-bcrypt/wp-password-bcrypt.php wp-content/mu-plugins/
#wp plugin uninstall password-bcrypt
composer require typisttech/wp-password-argon-two
# sessions
wp plugin install user-session-control --activate
# pwned passwords
wp plugin install disallow-pwned-passwords --activate
# user roles
wp plugin install user-role-editor --activate
# KeePass button
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-keepass-button/keepass-button.php

# WAF for WordPress

wget https://github.com/szepeviktor/waf4wordpress/raw/master/http-analyzer/waf4wordpress-http-analyzer.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/waf4wordpress/raw/master/core-events/waf4wordpress-core-events.php
#wget https://github.com/szepeviktor/waf4wordpress/raw/master/non-wp-projects/wp-login.php
#wget https://github.com/szepeviktor/waf4wordpress/raw/master/non-wp-projects/xmlrpc.php

# security suite + audit

# logbook
wp plugin install logbook --activate
# audit
wp plugin install wp-user-activity --activate
# simple audit
wp plugin install simple-history --activate
# Sucuri
#wp plugin install custom-sucuri sucuri-scanner --activate

# prevent spam

# installation: https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/mu-nofollow-robot-trap
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-nofollow-robot-trap/nofollow-robot-trap.php
# CF7 robot trap
wget -P wp-content/plugins/contact-form-7-robot-trap/ ${WPSZV}/contact-form-7-robot-trap/cf7-robot-trap.php
# Comment form robot trap
wget -P wp-content/plugins/comment-form-robot-trap/ ${WPSZV}/comment-form-robot-trap/comment-form-robot-trap.php
# Email address encoder
wp plugin install email-address-encoder --activate
# Stop spammers
#wp plugin install stop-spammer-registrations-plugin --activate
```

#### Restrictions

```bash
# lock session IP
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-lock-session-ip/lock-session-ip.php

# concurrent logins
#wp plugin install prevent-concurrent-logins --activate

# weak passwords
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-disallow-weak-passwords/disallow-weak-passwords.php

# user email addresses
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-banned-email-addresses/banned-email-addresses.php

# media
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-image-upload-control/image-upload-control.php
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-image-upload-control/image-upload-control-hu.php

# protect plugins
#wget -P wp-content/mu-plugins/ ${WPSZV}/mu-protect-plugins/protect-plugins.php
```

#### Object cache

```php
// In wp-config.php
define( 'WP_CACHE_KEY_SALT', 'SITE-SHORT_' );
$redis_server = array(
    'host'     => '127.0.0.1',
    'port'     => 6379,
    'auth'     => 'secret',
    'database' => 0,
);
```

```bash
wget -P wp-content/mu-plugins/ ${WPSZV}/mu-cache-flush-button/flush-cache-button.php

# Redis @danielbachhuber
wp plugin install wp-redis --activate
wp redis enable
wp transient delete-all

# Memcached @HumanMade
wget -P wp-content/ https://github.com/humanmade/wordpress-pecl-memcached-object-cache/raw/master/object-cache.php
wp transient delete-all

# File-based @emrikol from Automattic
#wp plugin install focus-object-cache
wget -P wp-content/ ${WPSZV}/focus-cache/object-cache.php
wp transient delete-all

# FileSystem, Sqlite, APC/u, Memcached, Redis @inpsyde
# See https://github.com/inpsyde/WP-Stash (inpsyde/wp-stash:dev-master) and https://www.stashphp.com/Drivers.html

# Tiny cache
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/tiny-cache/raw/master/tiny-translation-cache.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/tiny-cache/raw/master/tiny-nav-menu-cache.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/tiny-cache/raw/master/tiny-cache.php
```

Redis object cache as a service:
[Free 30 MB Redis instance by redislab](https://redislabs.com/redis-cloud)


#### Optimize HTML + HTTP

Resource optimization

```bash
# JPEG image quality
# add_filter( 'jpeg_quality', function ( $quality ) { return 91; } );

# Resource Versioning
wp plugin install resource-versioning --activate

# Tiny CDN
wp plugin install tiny-cdn --activate

# Minit
#wp plugin install https://github.com/kasparsd/minit/archive/master.zip
#wp plugin install https://github.com/markoheijnen/Minit-Pro/archive/master.zip

# Safe Redirect Manager
wp plugin install safe-redirect-manager --activate

# WP-FFPC
# backends: APCu, Memcached with ngx_http_memcached_module
# https://github.com/petermolnar/wp-ffpc
#wp plugin install https://github.com/petermolnar/wp-ffpc/archive/master.zip --activate

## Autoptimize - CONFLICTS with resource-versioning
##     define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );
#wp plugin install autoptimize --activate

#https://github.com/optimalisatie/above-the-fold-optimization
#https://github.com/o10n-x
```

Set up CDN.


#### Plugin fixes

MU Plugin Template

`custom-PROJECT-NAME.php`

```php
<?php
/*
Plugin Name: customizations (MU)
Version: 0.0.0
Description: This MU plugin contains customizations.
Plugin URI: https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/WordPress.md#plugin-fixes
Author: Viktor Szépe
*/
```

See [/webserver/wordpress/](/webserver/wordpress/) directory for its content.

### Plugin authors with enterprise mindset

- [Daniel Bachhuber](https://profiles.wordpress.org/danielbachhuber/#content-plugins)
  &bull; [GitHub](https://github.com/danielbachhuber?tab=repositories&type=source)
- [John Blackbourn](https://profiles.wordpress.org/johnbillion#content-plugins)
  &bull; [GitHub](https://github.com/johnbillion?tab=repositories&type=source)
- [Ben Huson](https://profiles.wordpress.org/husobj/#content-plugins)
  &bull; [GitHub](https://github.com/benhuson?utf8=✓&tab=repositories&q=&type=source)
- [10up](https://profiles.wordpress.org/10up#content-plugins)
  &bull; [GitHub](https://github.com/10up?utf8=%E2%9C%93&q=&type=source)
- [Inpsyde](https://profiles.wordpress.org/inpsyde#content-plugins)
  &bull; [GitHub](https://github.com/inpsyde?utf8=%E2%9C%93&q=&type=source)
- [Andrew Norcross](https://profiles.wordpress.org/norcross#content-plugins)
  &bull; [GitHub](https://github.com/norcross?utf8=%E2%9C%93&tab=repositories&q=&type=source)
- [XWP](https://profiles.wordpress.org/xwp#content-plugins)
  &bull; [GitHub](https://github.com/xwp?utf8=✓&q=&type=source&)
- [Frankie Jarrett](https://profiles.wordpress.org/fjarrett#content-plugins)
  &bull; [GitHub](https://github.com/fjarrett?utf8=%E2%9C%93&tab=repositories&q=&type=source)
- [Weston Ruter](https://profiles.wordpress.org/westonruter#content-plugins)
  &bull; [GitHub](https://github.com/westonruter?utf8=✓&tab=repositories&q=&type=source)
- [Scott Kingsley Clark](https://profiles.wordpress.org/sc0ttkclark#content-plugins)
  &bull; [GitHub](https://github.com/sc0ttkclark?utf8=✓&tab=repositories&q=&type=source)
- [Voce Platforms](https://profiles.wordpress.org/voceplatforms#content-plugins)
  &bull; [GitHub](https://github.com/voceconnect?utf8=✓&q=&type=source)
- [interconnect/it](https://profiles.wordpress.org/interconnectit#content-plugins)
  &bull; [GitHub](https://github.com/interconnectit?utf8=✓&q=&type=source)
- [Zack Tollman](https://profiles.wordpress.org/tollmanz#content-plugins)
  &bull; [GitHub](https://github.com/tollmanz?utf8=✓&tab=repositories&q=&type=source)

### On deploy and Staging->Production migration

@TODO Move to Production-website.md

Also in /webserver/Production-website.md

- `wp transient delete-all`
- `wp db query "DELETE FROM $(wp eval 'global $table_prefix;echo $table_prefix;')options WHERE option_name LIKE '%_transient_%'"`
- Remove development wp_options -> Option Inspector
- Delete unused Media files @TODO `for $m in files; search $m in DB;`
- `wp db optimize`
- WP-Sweep


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
```

1. https://DOMAIN.TLD (no trailing slash)
1. /home/PATH/TO/SITE (no trailing slash)
1. EMAIL@ADDRESS.ES (all addresses)
1. DOMAIN.TLD (now without https)

And manually replace constants in `wp-config.php`

Web-based search & replace tool:

```bash
wget -O srdb.php https://github.com/interconnectit/Search-Replace-DB/raw/master/index.php
wget https://github.com/interconnectit/Search-Replace-DB/raw/master/srdb.class.php
```

### Moving a site to a subdirectory

```bash
SUBDIR="project"
URL="$(wp option get home)"

# Change 'siteurl'
wp option set siteurl "${URL}/${SUBDIR}"

# Change URL in database
wp search-replace --precise --recurse-objects --all-tables-with-prefix "/wp-includes/" "/${SUBDIR}/wp-includes/"

# Change constants in wp-config.php
# - WP_CONTENT_DIR
# - WP_CONTENT_URL
# - TINY_CDN_INCLUDES_URL
# - TINY_CDN_CONTENT_URL
editor wp-config.php

# Move core to subdir
xargs -I % mv -v ./% ./${SUBDIR}/ <<"EOF"
wp-admin
wp-includes
licenc.txt
license.txt
olvasdel.html
readme.html
wp-activate.php
wp-blog-header.php
wp-comments-post.php
wp-config-sample.php
wp-cron.php
wp-links-opml.php
wp-load.php
wp-login.php
wp-mail.php
wp-settings.php
wp-signup.php
wp-trackback.php
xmlrpc.php
EOF
cp -v ./index.php ./${SUBDIR}/

# Modify /index.php
sed -e "s|'/wp-blog-header\\.php'|'/${SUBDIR}/wp-blog-header.php'|" -i ./index.php

# Move files from parent directory
mv -v ../wp-config.php ./
mv -v ../waf4wordpress-http-analyzer.php ./

# Edit "path:" in wp-cli.yml
editor ../wp-cli.yml

# Fix Apache VirtualHost configuration

# Flush cache
wp cache flush
```

### Signature

```bash
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/debian-server-tools/raw/master/webserver/wordpress/szv-signature.php
```
