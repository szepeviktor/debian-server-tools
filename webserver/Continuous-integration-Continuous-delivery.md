 # Continuous integration and Continuous delivery

How to design and implement CI and CD.

### CI

- Run in a premade container or install OS packages
- Display environment information
- Set access credentials
- Cache OS and programming language library packages
- Check programming language and framework version compatibility
- Check package management configuration (validate & normalize)
- Check outdated packages and known security vulnerabilities
- Build code
- Configure application
- Check non-ASCII characters in the source code
  (non-English alphabets, whitespace characters, control characters) :zero:
- Lint source code (syntax check) :one:
- Lint template files
- Check coding style and adhere to EditorConfig :two:
- Magic Number Detector
- Copy-Paste Detector
- **Do static analysis** :three:
- Run (unit and functional) tests
- Measure code coverage
- Check route methods (controllers of routes)
- Custom checks and warnings
- Display logs in CI output or upload logs as artifacts
- Start CD by SSH-ing to own server (`restrict,command` in authorized_keys and `DenyUsers` in sshd.conf)
- Wipe sensitive data

### CD

- Possible constrains:
  * successful tests
  * do not run on PR-s
  * our repo
  * specific branch
  * tag in commit message `[deploy:prod]`
  * deploy head commit only
  * optional manual start ([GitLab manual actions](https://gitlab.com/help/ci/yaml/README.md#manual-actions))
- Do not run as root user
- Keep deploy configuration in a file
- Log every output to a file, log start and finish to syslog
- Limit execution time of time-consuming steps (timeout)
- Optionally back up project files before starting to deploy
- Create a bot user on the server for git access with SSH key (`@companybot`)
- List changes in current project files
- [Check for maintenance mode](/webserver/laravel/Commands/IsDownForMaintenance.php),
  Turn on maintenance mode `php artisan down`
  covering static resource, page, AJAX and API requests
- Clear caches (configuration, routes, application, template etc.)
- Wait for to finish and disable cron jobs and background workers after clearing caches (email piped to a program)
- Identify git repository and branch
- Checkout by commit hash (not by branch HEAD)
- At least **lint the source code**
- Don't deploy testing packages
- Enable production optimizations in package manager
- Build code
- Run database migrations
- Turn off maintenance mode
- Populate caches (application, OPcache, `wp rewrite flush`)
- Run at least 1 basic functional or unit test (e.g. log in or display dashboard)
- Check HTML output
- Special sudo configuration for reloading PHP-FPM or Cachetool
- **Alert on failure**
- "Was down for X seconds"
- Send email, Slack, Trello or Google Hangouts notification

### Coding style / Coding standard

* Tool: squizlabs/php_codesniffer # `phive install phpcs`
* Tool: dealerdirect/phpcodesniffer-composer-installer

- [commenting rules](https://github.com/squizlabs/PHP_CodeSniffer/tree/master/src/Standards/PEAR/Sniffs/Commenting)
- wp-coding-standards/wpcs
- automattic/phpcs-neutron-standard , automattic/phpcs-neutron-ruleset
- slevomat/coding-standard
- object-calisthenics/phpcs-calisthenics-rules
- consistence/coding-standard
- symplify/coding-standard

### Static analysis

* Tool: phpstan/phpstan # `phive install phpstan`
* Tool: dave-liddament/sarb # `phive install sarb`

- ekino/phpstan-banned-code
- phpstan/phpstan-strict-rules
- phpstan/phpstan-deprecation-rules
- ergebnis/phpstan-rules
- thecodingmachine/phpstan-strict-rules
- pepakriz/phpstan-exception-rules
- nunomaduro/larastan
- szepeviktor/phpstan-wordpress

### Deploying WordPress

Trigger theme setup.

```bash
wp eval '$old_theme=wp_get_theme("our-theme"); do_action("after_switch_theme", $old_theme->get("Name"), $old_theme);'
```

Use a common `deploy` hook.

```bash
wp eval 'do_action("deploy");'
```

Install languages.

- From wordpress.org: `wp language plugin install wordpress-seo hu_HU`
- From git repository: `apt-get install gettext # msgfmt`
- Exported from translate.wordpress.org:

```bash
TWPORG_URL="https://translate.wordpress.org/projects/wp-plugins/${PLUGIN}/stable/hu/default/export-translations/?format=${FORMAT}"
wget -O wp-content/languages/plugins/wordpress-seo-hu_HU.mo "$TWPORG_URL"
wp language plugin is-installed wordpress-seo hu_HU
```

Tag-category collision.

```bash
{ wp term list post_tag --field=slug; wp term list category --field=slug; }|sort|uniq -d
```

<!-- https://antoinevastel.com/bot%20detection/2018/01/17/detect-chrome-headless-v2.html -->


### Looking at new WordPress code

1. [Main plugin file parts](https://github.com/szepeviktor/phpstan-wordpress/blob/master/README.md#make-your-code-testable)
1. [Static analysis](https://github.com/szepeviktor/phpstan-wordpress)
1. [Code quality](https://github.com/nunomaduro/phpinsights)
1. Tools for themes
    - https://themecheck.info/
    - https://wordpress.org/plugins/theme-check/
    - [WPThemeReview Standard for PHP_CodeSniffer](https://github.com/WPTRT/WPThemeReview)
1. Security
    - https://github.com/WordPress/WordPress-Coding-Standards/tree/develop/WordPress/Sniffs/Security
    - https://coderisk.com/ by RIPS Technologies
    - https://wpvulndb.com/
