# Drupal setup

## Prerequisites

- drush from debian-setup.sh
- drushrc `sites/default/drushrc.php`: `$options['uri'] = "http://<DOMAIN.TLD>/";`
- more config: https://raw.githubusercontent.com/drush-ops/drush/master/examples/example.drushrc.php
- first run: `sudo -u $U -- drush status`
- PHP-FPM pool: `php_admin_value[allow_url_fopen] = On`

## Modules

### Browse modules

`sudo -u $U -- drush en module_filter -y`

### APC

Cache backend.

`sudo -u $U -- drush en apc -y`

`settings.php`:

```php
$conf['cache_backends'][] = 'sites/all/modules/apc/drupal_apc_cache.inc';
$conf['cache_default_class'] = 'DrupalAPCCache';
//$conf['apc_show_debug'] = TRUE;  // Remove the slashes to use debug mode.
```

### Entity cache

Object cache.

`sudo -u $U -- drush en entitycache -y`

### Alternative Database Cache

`sudo -u $U -- drush en adbc -y`

### Fail2ban

https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/wordpress-fail2ban/non-wp-projects/drupal-fail2ban/fail2ban_404

### Mollom

```ini
suhosin.get.max_array_index_length = 128
suhosin.post.max_array_index_length = 128
suhosin.request.max_array_index_length = 128
```

### Translation updates

`sudo -u $U -- drush en l10n_update -y`

admin/config/regional/translate/update

### Sitemap

Enable inclusion per content type.

`sudo -u $U -- drush en xmlsitemap -y`

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
