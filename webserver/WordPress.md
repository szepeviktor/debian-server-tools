# WordPress website lifecycle

## Where do I find ...?

- Development environment: /webserver/Wp-config-dev.md
- Development tools: wordpress-sitebuild/
- Production environment: /webserver/Production-website.md
- Production on cPanel and migration to cPanel: wordpress-plugin-construction/shared-hosting-aid/cPanel/cPanel-WordPress-setup.md
- Content plugins: wordpress-plugin-construction/README.md
- WordPress installation: here + secret dir + git + migration

### Secret Directory structure

```
$DOCROOT─┬─index.php
         ├─wp-config.php
         ├─$CORE─┬─wp-load.php
         │       ├─wp-login.php
         │       ├─wp-admin/
         │       └─wp-includes/
         └─static/
```

wp-cli.yml options: path, user ...

`./wp-createdb.sh`

```bash
wp core config --dbname="$DBNAME" --dbuser="$DBUSER" --dbpass="$DBPASS" \
    --dbhost="$DBHOST" --dbprefix="prod" --dbcharset="$DBCHARSET" --extra-php <<EOF
EOF
wp option set home "$WPHOMEURL"
wp option set blog_public "0"
wp option set admin_email "support@company.net"
```

@TODO Migrate to wp-lib



@TODO Move to add-prg-site...
### Redis object cache

[Free 30 MB Redis instance by redislab](https://redislabs.com/redis-cloud)

```bash
# Redis server
apt-get install -y redis-server

# PHP 5.6 extension
pecl install redis
echo -e "; priority=20\nextension=redis.so" > /etc/php5/mods-available/redis.ini
php5enmod redis
php -m | grep -Fx "redis"

# PHP 7 extension
apt-get install php7.0-dev re2c
git clone https://github.com/phpredis/phpredis.git
cd phpredis/ && git checkout php7
# igbinary disables inc() and dec()
#phpize7.0 && ./configure --enable-redis-igbinary && make && make install
phpize7.0 && ./configure && make && make install
chmod -c -x /usr/lib/php/20151012/redis.so
echo -e "; priority=20\nextension=redis.so" > /etc/php/7.0/mods-available/redis.ini
phpenmod -v 7.0 -s ALL redis
php -m | grep -Fx "redis" && php tests/TestRedis.php --class Redis
echo "FLUSHALL" | nc -C -q 10 localhost 6379

# PHP 7 extension from dotdeb
apt-get install -y php7.0-redis
```

### Memcached control panel

```bash
echo stats | nc localhost 11211 | grep bytes
mkdir phpMemAdmin; cd phpMemAdmin/
echo '{ "require": { "clickalicious/phpmemadmin": "~0.3" }, "scripts": { "post-install-cmd":
    [ "Clickalicious\\PhpMemAdmin\\Installer::postInstall" ] } }' > composer.json
composer install; composer install
mv web memadmin
mv ./app/.config.dist ./app/.config
sed -i -e '0,/"username":.*/s//"username": null,/' ./app/.config
sed -i -e '0,/"password":.*/s//"password": null,/' ./app/.config
```

Apache config

```apache
# phpMemAdmin
Alias "/memadmin" "/home/${SITE_USER}/website/phpMemAdmin/memadmin"
SetEnvIfNoCase Authorization "(.+)" HTTP_AUTHORIZATION=$1
ProxyPassMatch "^/memadmin/.+\.php$" "unix:///run/php/php7.0-fpm-${SITE_USER}.sock|fcgi://localhost/home/${SITE_USER}/website/phpMemAdmin"
```

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
wget https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-disable-updates/disable-updates.php

# disable comments
wget -P wp-content/mu-plugins/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu.php
wget -P wp-content/mu-plugins/disable-comments-mu/ https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu/comments-template.php

# smilies
wp plugin install classic-smilies --activate

# mail
wp plugin install classic-smilies wp-mailfrom-ii smtp-uri --activate
#wget -P wp-content/mu-plugins/ https://github.com/danielbachhuber/mandrill-wp-mail/raw/master/mandrill-wp-mail.php
wp eval 'var_dump(wp_mail("admin@szepe.net","First outgoing",site_url()));'
# define( 'SMTP_URI', 'smtp://FOR-THE-WEBSITE%40DOMAIN.TLD:PWD@localhost' );

# multilanguage
wp plugin install polylang --activate
```

#### Security

```bash
# Fail2ban Wordpress
wget https://github.com/szepeviktor/wordpress-fail2ban/raw/master/block-bad-requests/wp-fail2ban-bad-request-instant.inc.php
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-fail2ban/raw/master/mu-plugin/wp-fail2ban-mu-instant.php

# users
wp plugin install password-bcrypt
cp wp-content/plugins/password-bcrypt/wp-password-bcrypt.php wp-content/mu-plugins/
wp plugin uninstall password-bcrypt
# mu-lock-session-ip
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-lock-session-ip/lock-session-ip.php
wp plugin install prevent-concurrent-logins --activate
wp plugin install user-session-control --activate
# mu-totp-login
# https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/mu-totp-login
# user role editor
wp plugin install user-role-editor --activate

# security suite + audit
wp plugin install sucuri-scanner custom-sucuri --activate
# simple audit
wp plugin install simple-history --activate

# mail/spam
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-nofollow-robot-trap/nofollow-robot-trap.php
# Install: https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/mu-nofollow-robot-trap
wget -P wp-content/plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/contact-form-7-robot-trap/cf7-robot_trap.php
wp plugin install obfuscate-email --activate
```

#### Forcing

```bash
# protect plugins
wget -P wp-content/mu-plugins/ https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-protect-plugins/protect-plugins.php
```

#### Object cache

```bash
# APCu @l3rady
# DANGER! apcu is not available from CLI by default during WP-Cron
wget -P wp-content/ https://github.com/l3rady/WordPress-APCu-Object-Cache/raw/master/object-cache.php
## Worse: wp plugin install apcu
# Memcached @tollmanz
wget -P wp-content/ https://github.com/tollmanz/wordpress-pecl-memcached-object-cache/raw/master/object-cache.php
# Redis @danielbachhuber
wp plugin install wp-redis
wp transient delete-all
ln -sv plugins/wp-redis/object-cache.php wp-content/
```

```php
// Remember adding WP_CACHE_KEY_SALT in wp-config.php
$redis_server = array(
    'host' => '127.0.0.1',
    'port' => 6379,
);
```

#### Optimize HTML + HTTP

Resource optimization

```bash
# safe redirect manager
wp plugin install safe-redirect-manager --activate

# ?
wp plugin install resource-versioning <--> autoptimize --activate
# define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );

# CDN, Page Cache, Minify
wp plugin install w3-total-cache --activate
```

Set up CDN.

#### Plugin fixes

Revolution Slider fix

```php
/*
 * Trigger fail2ban on Revolution Slider upload attempt.
 *
 * @revslider/revslider_admin.php:389
 *     case "update_plugin":
 * Comment out
 *     //self::updatePlugin(self::DEFAULT_VIEW);
 */
error_log( 'Break-in attempt detected: ' . 'revslider_update_plugin' );
exit;
```

TGM-Plugin-Activation plugin

```php
add_action( 'after_setup_theme', 'o1_disable_tgmpa' );
function o1_disable_tgmpa() {
    remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
    remove_action( 'tgmpa_register', 'CUSTOM-FUNCTION' );
}
```

WPBakery Visual Composer plugin

```php
add_action( 'plugins_loaded', 'o1_disable_vc_plugin_updates' );
function o1_disable_vc_plugin_updates() {
    global $vc_manager;
    $vc_manager->disableUpdater( true );
}
```

Easy Social Share Buttons plugin

```php
add_action( 'plugins_loaded', 'o1_disable_essb_plugin_updates' );
function o1_disable_essb_plugin_updates() {
    global $essb_manager;
    $essb_manager->disableUpdates( true );
}
```

Envato Market plugin for ThemeForest updates

```bash
wp plugin install https://envato.github.io/wp-envato-market/dist/envato-market.zip --activate
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

`wp search-replace --precise --recurse-objects --all-tables-with-prefix`
`wp search-replace --precise --recurse-objects --all-tables-with-prefix ...`
`wp search-replace --precise --recurse-objects --all-tables-with-prefix`
`wp search-replace --precise --recurse-objects --all-tables-with-prefix`

1. http://DOMAIN.TLD or https (no trailing slash)
1. /home/PATH/TO/SITE (no trailing slash)
1. EMAIL@ADDRESS.ES (all addresses)
1. DOMAIN.TLD (now without http)

Manual replace constants in `wp-config.php`

### Moving a site to a subdirectory

1. siteurl += /site
1. search-and-replace: /wp-includes/ -> /site/wp-includes/
1. search-and-replace: /wp-content/ -> /static/

S&R links...


@TODO wp-lib
