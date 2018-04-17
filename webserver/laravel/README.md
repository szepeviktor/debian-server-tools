# Running a Laravel application

Laravel upgrade: https://laravelshift.com/

### Caches

Use [Redis PECL extension](https://laravel.com/docs/5.6/redis#phpredis) instead of Predis.

- Compiled classes `/bootstrap/cache/compiled.php`
  [removed in 5.4](https://github.com/laravel/framework/commit/09964cc8c04674ec710af02794f774308a5c92ca#diff-427cac03b212e5fd24785d55149d3aea)
- Services `/bootstrap/cache/services.php` - flushed in composer script `post-autoload-dump`
- Discovered packages `/bootstrap/cache/packages.php` - flushed in composer script `post-autoload-dump`
- Configuration cache `/bootstrap/cache/config.php` - flushed by `artisan config:clear`
- Routes cache `/bootstrap/cache/routes.php` - flushed by `artisan route:clear`
- Application cache (`CACHE_DRIVER`) - flushed by `artisan cache:clear`
- Blade templates cache `/storage/framework/views/*.php` - flushed by `artisan view:clear`

See `/vendor/laravel/framework/src/Illuminate/Foundation/Application.php`

Caching depends on `APP_ENV` variable.
