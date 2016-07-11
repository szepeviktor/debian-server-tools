# WordPress website lifecycle

## Core and essentials

`wp download core`

### Directory structure

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
editor wp-config.php
#     require_once __DIR__ . '/wp-fail2ban-bad-request-instant.inc.php';
wget https://github.com/szepeviktor/wordpress-fail2ban/raw/master/block-bad-requests/wp-fail2ban-bad-request-instant.inc.php

read -r WPHOMEURL
wp core install --url="${WPHOMEURL}/${COMPANY}" --title="Site Title" \
    --admin_user="$ME" --admin_password="$MYPASS" --admin_email=viktor@szepe.net

wp option set home "$WPHOMEURL"
wp option set blog_public "0"
wp option set admin_email "support@company.net"
```

@TODO Migrate to wp-lib


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

Cache key salt in `wp-config.php`

```php
define( 'WP_CACHE_KEY_SALT', 'COMPANY_' );
/*
$redis_server = array(
    'host' => '127.0.0.1',
    'port' => 6379,
);
*/
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

APCu object cache

https://github.com/l3rady/WordPress-APCu-Object-Cache

```bash
wp plugin install apcu
wp plugin install https://github.com/l3rady/WordPress-APCu-Object-Cache/raw/master/object-cache.php
ln -sv wp-content/plugins/wp-redis/object-cache.php wp-content/
```

### Plugins

```bash
mkdir wp-content/mu-plugins
cd wp-content/mu-plugins/

# Fail2ban Wordpress
wget https://github.com/szepeviktor/wordpress-fail2ban/raw/master/mu-plugin/wp-fail2ban-mu-instant.php

# protect plugins
wget https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-protect-plugins/protect-plugins.php

# password bcrypt
wget https://github.com/szepeviktor/password-bcrypt/raw/wp/wp-password-bcrypt.php

# disable updates
wget https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/mu-disable-updates/disable-updates.php

# disable comments
wget https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu.php
wget -P disable-comments-mu https://github.com/solarissmoke/disable-comments-mu/raw/master/disable-comments-mu/comments-template.php

# google analytics
wget https://github.com/szepeviktor/wordpress-plugin-construction/raw/master/google-universal-analytics/google-universal-analytics.php

# redis
wp plugin install wp-redis
ln -sv wp-content/plugins/wp-redis/object-cache.php wp-content/
wp transient delete-all
# Add WP_CACHE_KEY_SALT in wp-config.php

# apcu
# DANGER! apcu is not available from CLI by default during WP-Cron
## worse: wp plugin install apcu
wp plugin https://github.com/l3rady/WordPress-APCu-Object-Cache/archive/master.zip
ln -sv wp-content/plugins/WordPress-APCu-Object-Cache-master/object-cache.php wp-content/

# mail from
wp plugin install classic-smilies wp-mailfrom-ii --activate

# smtp uri
wp plugin install smtp-uri --activate

# safe redirect manager
wp plugin install safe-redirect-manager --activate

# user role editor
wp plugin install user-role-editor --activate
```

#### Optimize

Resource optimization

`wp plugin install resource-versioning autoptimize --activate`

`define( 'AUTOPTIMIZE_WP_CONTENT_NAME', '/static' );`

TGM-Plugin-Activation plugin

```php
add_action( 'after_setup_theme', 'o1_disable_theme_updates' );
function o1_disable_theme_updates() {
    remove_action( 'admin_init', 'tgmpa_load_bulk_installer' );
    remove_action( 'tgmpa_register', 'theme_required_plugins' );
}
```

WPBakery Visual Composer plugin

```php
add_action( 'plugins_loaded', 'o1_disable_plugin_updates' );
function o1_disable_plugin_updates() {
    global $vc_manager;
    $vc_manager->disableUpdater( true );
}
```

Envato Market plugin for ThemeForest updates

`wp plugin install https://envato.github.io/wp-envato-market/dist/envato-market.zip --activate`

#### SMTP URI

`wp eval 'wp_mail("admin@szepe.net","first outgoing",site_url());'`

### On deploy and Staging->Production migration

(Also in Production-website.md)

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
