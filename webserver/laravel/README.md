# Running a Laravel application

Laravel upgrade service: https://laravelshift.com/

### Application setup in production

- Document everything in `hosting.yml`
- Git repository and SSH key
- Default Apache virtualhost + PHP FPM pool + SSL certificate
- Apache config
- PHP extensions and directives (declared also in `php-env-check.php`)
- Local "locales", see [Locale-gettext.md](./Locale-gettext.md)
- `.env` variables
- Database seeding and/or import
- Media import
- [CD](/webserver/Continuous-integration-Continuous-delivery.md) testing
- Laravel queues
- Cron jobs (sitemap, queue checks)
- Outbound email: Laravel SwiftMailer or `mail()` and local queuing MTA
- Log reporting (`laravel-report.sh`)
- Periodic git status check (`git.sh`)
- Monitor front page with Monit
- Register to webmaster tools
- Think of other environments (development/staging/beta/demo)

### In-app security

- Use [Argon2 hashing](https://laravel.com/docs/5.6/hashing)
- WordPress Fail2ban WAF patched
- HTTP method not in routes
- HTTP 404
- CSRF token mismatch
- Failed login attempts
- Non-empty hidden field in forms

#### Security Exceptions

```php
protected $securityExceptions = [
        \Illuminate\Session\TokenMismatchException::class,
        \Illuminate\Validation\ValidationException::class,
        \Illuminate\Auth\Access\AuthorizationException::class,
        \Illuminate\Database\Eloquent\ModelNotFoundException::class,
        \Symfony\Component\HttpKernel\Exception\HttpException::class,
        \Symfony\Component\HttpKernel\Exception\NotFoundHttpException::class,
];
```

### Laravel caches

Use [Redis PECL extension](https://laravel.com/docs/5.6/redis#phpredis) instead of Predis,
and the [key hash tag](https://laravel.com/docs/5.6/queues#driver-prerequisites).

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
