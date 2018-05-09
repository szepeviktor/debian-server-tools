# Running phpstan - PHP Static Analysis Tool

### Trying to use phpstan

- phpstan alone
- phpstan + weebly/phpstan-laravel
- barryvdh/laravel-ide-helper + phpstan


```bash
composer create-project --prefer-dist "laravel/laravel:^5.6"
cd laravel/
vendor/bin/phpstan analyze -a ./_ide_helper_models.php -l 7 app/

composer require --dev phpstan/phpstan:dev-master
composer require --dev barryvdh/laravel-ide-helper:dev-master
#editor vendor/laravel/framework/src/Illuminate/Database/Eloquent/Model.php # Add class comment
./artisan ide-helper:generate
vendor/bin/phpstan analyze -a ./_ide_helper_models.php -l 7 app/

composer require --dev "phpstan/phpstan:^0.9"
composer require --dev weebly/phpstan-laravel
printf 'includes:\n  - vendor/weebly/phpstan-laravel/extension.neon\n' > phpstan.neon
vendor/bin/phpstan analyze -c ./phpstan.neon -l 7 app/
```
