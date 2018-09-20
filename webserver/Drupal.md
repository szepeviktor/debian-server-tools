# Drupal installation

https://drushcommands.com/

## Prerequisites

- drush, see: /debian-setup.sh
- Create `sites/default/drushrc.php` (see below)
- Configuration: https://github.com/drush-ops/drush/blob/master/examples/example.drushrc.php
- PHP-FPM pool: `php_admin_value[allow_url_fopen] = On`
- first run: `drush status`

```php
<?php
$options['uri'] = "https://DOMAIN.TLD/";
// FIXME set temp directory, see includes/filesystem.inc:drush_find_tmp();
```

## Modules

### Browse modules

`drush pmi --format=yaml`

### Enable module

`drush en <MODULE-NAME> -y`

### Caches

#### APC cache backend.

`drush en apc -y`

`settings.php`:

```php
$conf['cache_backends'][] = 'sites/all/modules/apc/drupal_apc_cache.inc';
$conf['cache_default_class'] = 'DrupalAPCCache';
//$conf['apc_show_debug'] = TRUE;  // Uncomment to enable debug mode
```

#### Object cache

`drush en entitycache -y`

Entity caching is supported in Drupal 8.

#### Preload page cache

See: /webserver/preload-cache.sh

### Fail2ban

https://github.com/szepeviktor/wordpress-fail2ban

### Mollom

```ini
suhosin.get.max_array_index_length = 128
suhosin.post.max_array_index_length = 128
suhosin.request.max_array_index_length = 128
```

### Automatic translation updates

`drush en l10n_update -y`

admin/config/regional/translate/update

### Sitemap

Enable inclusion per content type.

`drush en xmlsitemap -y`

## CDN

`drush en cdn -y`

## Drupal menus

- All options: admin/config
- admin/config/media/file-system
- JPEG qulite: 90% admin/config/media/image-toolkit
- admin/config/development/performance
- admin/config/regional
- Backup settings.php && database

### General website tasks

- logging/tmp/upload/session + gc
- mail from
- root files

### Cron

- http://cgit.drupalcode.org/drush/plain/docs/cron.html
- /usr/local/bin/drush --quiet --root=/home/webuser/website/code core-cron
- /usr/bin/wget -qO- "https://www.example.com/cron.php?cron_key=AAAAAAAAAAAAAAAAAA1111111111111111111111111"

### Drupal 6 Redis cache

Use drush with PHP 5.6: `DRUSH_PHP=/usr/bin/php5.6 exec /opt/drush/vendor/bin/drush "$@"`

1. Download [Cache Backport (D7 to D6) module](https://www.drupal.org/project/cache_backport/releases)
   `drush5.6 pm-download cache_backport-6.x-1.0-rc4`
1. Download [Redis module for D7](https://www.drupal.org/project/redis/releases):
   `drush5.6 pm-download redis-7.x-3.17`
1. Rename module `mv sites/all/modules/contrib/redis sites/all/modules/contrib/redis_d7`
1. For documentation see `sites/all/modules/contrib/cache_backport/INSTALL.txt`
   and `sites/all/modules/contrib/redis_d7/README.txt`
1. Flush cache: `drush5.6 cache-clear all`
1. Configure to use phpredis (PECL) - not Predis - in `sites/default/settings.php` (see code below)
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
$conf['redis_client_base'] = 2; // db2=examplesite
$conf['cache_prefix'] = 'prefix_';
```

## Set up Drupal

```bash
cd website/
drush dl drupal --drupal-project-rename=code
cd code/
drush site-install standard \
    --db-url='mysql://DB-USER:DB-PASS@localhost/DB-NAME' \
    --site-name=SITE-NAME --account-name=USER-NAME --account-pass=USER-PASS

drush --root=DOCUMENT-ROOT vset --yes file_private_path "PRIVATE-PATH"
drush --root=DOCUMENT-ROOT vset --yes file_temporary_path "UPLOAD-DIRECTORY"
drush --root=DOCUMENT-ROOT vset --yes cron_safe_threshold 0
```

See /webserver/preload-cache.sh
