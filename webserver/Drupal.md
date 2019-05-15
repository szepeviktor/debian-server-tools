# Drupal installation

Drupal version 7.x

https://www.aegirproject.org/

### Drush 8

- [/debian-setup/php-drush](/debian-setup/php-drush)
- Create `sites/default/drushrc.php` , see code below
- [Configuration](https://github.com/drush-ops/drush/blob/8.x/examples/example.drushrc.php)
- First run: `drush status # --fields=drupal-version`

```php
<?php /** sites/default/drushrc.php */
$options['uri'] = 'https://DOMAIN.TLD/';
// FIXME set temp directory, see includes/filesystem.inc:drush_find_tmp();
```

https://drushcommands.com/

### PHP configuration

PHP-FPM configuration

```ini
; Drupal
php_admin_value[allow_url_fopen] = On
; Is it ineffective as mbstring.encoding_traslation is disabled
php_admin_value[mbstring.http_input] = pass
php_admin_value[mbstring.http_output] = pass
```

### Drupal installation

```bash
cd website/
drush dl drupal --drupal-project-rename=code # --default-major=6
cd code/
drush site-install standard \
    --db-url='mysql://DB-USER:DB-PASS@localhost/DB-NAME' \
    --site-name=SITE-NAME --site-mail=user@example.com \
    --account-name=USER-NAME --account-pass=USER-PASS

# All options: /admin/config  /admin/by-module

# /admin/config/media/file-system
drush vset file_private_path "PRIVATE-PATH"
drush vset file_temporary_path "UPLOAD-TMP-DIRECTORY"
# Disable cron - /admin/config/system/cron
drush vset cron_safe_threshold 0
# /admin/config/system/site-information
drush vset site_mail webmaster@example.com
drush vset site_403 /forbidden
drush vset site_404 /not-found
# /admin/config/content/webform  /admin/build/contact
drush vset webform_default_from_address info@example.com
drush vset webform_default_from_name "From Name"
drush vset webform_default_subject "Subject"
# /admin/config/development/performance
drush vset cache 1
drush vset block_cache 1
# /admin/settings/jquery_update
drush vset jquery_update_compression_type min
# /admin/config/media/image-toolkit
drush vset image_jpeg_quality 90
# /admin/config/regional/settings
drush vset site_default_country HU
drush vset date_first_day 1
drush vset date_default_timezone Europe/Budapest

#D6 drush vset file_directory_temp "UPLOAD-TMP-DIRECTORY"
#D6 drush vset cron_safe_threshold 0
#D6 drush vset date_default_timezone 3600 # 7200
#D6 drush vset date_default_timezone_name Europe/Budapest

# /admin/people/create
drush user-information --format=list --fields=name 1
drush user-block 1
drush user-create viktor --mail=viktor@szepe.net --password="12345"
drush user-add-role administrator viktor

#D6 drush user-add-role admin viktor
```

Composer-based: https://github.com/drupal-composer/drupal-project

Preload page cache: [/webserver/preload-cache.sh](/webserver/preload-cache.sh)

### Modules

Disable development modules: `drush dis -y devel`

Disable syslog logging: `drush dis -y syslog`

Browse modules: `drush pmi --format=yaml`

Enable module: `drush en -y MODULE`

Report 403 and 404: https://github.com/szepeviktor/waf4wordpress/tree/master/non-wp-projects/drupal8-fail2ban
and [`Http_Analyzer`](https://github.com/szepeviktor/waf4wordpress/tree/master/http-analyzer)

APC cache backend: `drush en -y apc`

Add this to `settings.php`

```php
$conf['cache_backends'][] = 'sites/all/modules/apc/drupal_apc_cache.inc';
$conf['cache_default_class'] = 'DrupalAPCCache';
//$conf['apc_show_debug'] = TRUE; // Uncomment to enable debug mode
```

Object cache: `drush en -y entitycache`

Only for Drupal 7 (not for 6, built into 8).

Automatic translation updates: `drush en -y l10n_update`

`/admin/config/regional/translate/update`

CDN: `drush en -y cdn`

Sitemap: `drush en -y xmlsitemap xmlsitemap_node`

Enable inclusion per content type, add to `robots.txt`

`/admin/content/types`

Mail sending: `drush en -y smtp`

### Check libraries

Integrity and versions.

- `plugins/`
- `sites/all/libraries/`
- `sites/all/modules/contrib/jquery_update/replace/`
- `sites/all/modules/contrib/jquery_ui/jquery.ui/`

### Cron

http://cgit.drupalcode.org/drush/plain/docs/cron.html

```bash
#D6 DRUSH_PHP=/usr/bin/php5.6
/usr/local/bin/drush --root=/home/USER/website/code cron --quiet
/usr/bin/wget -q -O- "https://www.example.com/cron.php?cron_key=AAAAA11111111111"
```

### Drupal Redis cache

1. Download: `drush dl -y redis`
1. Flush cache: `drush cache-clear all`
1. Configure to use phpredis (PECL) - not Predis - in `sites/default/settings.php` see code below
1. Install: `drush en -y redis`
1. Flush cache: `drush cache-clear all`
1. Check Redis keys: `echo 'INFO keyspace' | redis-cli`

```php
/**
 * Cache settings:
 */
$conf['redis_client_interface'] = 'PhpRedis';
$conf['redis_client_base']      = 2; // db2:examplesite
$conf['cache_prefix']           = 'prefix_'; // Cache key prefix
$conf['lock_inc']               = 'sites/all/modules/redis/redis.lock.inc';
$conf['path_inc']               = 'sites/all/modules/redis/redis.path.inc';
$conf['cache_backends'][]       = 'sites/all/modules/redis/redis.autoload.inc';
$conf['cache_default_class']    = 'Redis_Cache';
```

`/admin/config/development/performance/redis`

### Drupal 6 Redis cache

Use drush with PHP 5.6: `DRUSH_PHP=/usr/bin/php5.6 exec /usr/local/bin/drush "$@"`

1. Download [Cache Backport (D7 to D6) module](https://www.drupal.org/project/cache_backport/releases)
   `drush5.6 pm-download cache_backport-6.x-1.0-rc4`
1. Download [Redis module for D7](https://www.drupal.org/project/redis/releases):
   `drush5.6 pm-download redis-7.x-3.17`
1. Rename module `mv sites/all/modules/contrib/redis sites/all/modules/contrib/redis_d7`
1. For documentation see `sites/all/modules/contrib/cache_backport/INSTALL.txt`
   and `sites/all/modules/contrib/redis_d7/README.txt`
1. Flush cache: `drush5.6 cache-clear all`
1. Configure to use phpredis (PECL) - not Predis - in `sites/default/settings.php` see code below
1. Enable cache: `drush5.6 pm-enable cache_backport -y`
1. Flush cache: `drush5.6 cache-clear all`
1. Check Redis keys: `echo 'INFO keyspace' | redis-cli`

```php
/**
 * Cache settings:
 */
$conf['cache_inc'] = 'sites/all/modules/contrib/cache_backport/cache.inc';
$conf['cache_backends'][] = 'sites/all/modules/contrib/redis_d7/redis.autoload.inc';
$conf['cache_default_class'] = 'Redis_Cache';
$conf['redis_client_interface'] = 'PhpRedis';
$conf['redis_client_base'] = 2; // db2:examplesite
$conf['cache_prefix'] = 'prefix_';
```
