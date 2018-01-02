# PHP development notes

How to move fast while keeping the codebase clean?

See an article on [Moving Fast With High Code Quality](https://engineering.quora.com/Moving-Fast-With-High-Code-Quality)
and [clearPHP rules](https://github.com/dseguy/clearPHP)

### Forces influencing development

- First an foremost keeping the codebase clean to avoid rewrites in long term
- Make profit!
- Other's interest in integration with your project (API)
- Move fast with development, don't use a tool if it slows down development
- Keep developer morale high
- Think about the far future when making decisions today

### Editor settings

Bits and bytes.

- Execute bit off
- UTF-8 encoding without BOM
- LF lineends
- Consistent indentation
- **Strip trailing spaces**

[PSR2 ruleset](https://github.com/squizlabs/PHP_CodeSniffer/blob/master/src/Standards/PSR2/ruleset.xml)

### Use others' work

- Consider [PSR-s](http://www.php-fig.org/psr/)
- Frameworks/CMS-s
- Packages/Libraries
- SaaS
- Development tools (CI)
- Build and deployment tools
- Application monitoring (performance, errors)

### CI outside tests

What to include in continuous integration with 0% code coverage?
(no unit tests, no functional test)

Use Docker **containers** for testing.

- Modern task runner (composer:scripts, consolidation/robo, npm only, grunt, gulp)
- Package installation (hirak/prestissimo)
- Git hook integration (phpro/grumphp)
- Syntax check (php-parallel-lint)
- PSR-2-based coding style (phpcs)
- Warn on `TODO` and `FIXME`: Move it into issues! (phpcs)
- [Static analysis](https://www.youtube.com/watch?v=majpU-_ShB0) (phpstan, phan)
- Mess Detector (phpmd)
- Critical vulnerabilities in dependencies ([Gemnasium](https://gemnasium.com/))
- Metrics (phpmetrics)
- Build assets (webpack)

### CI with tests

- PHPUnit
- Measure code coverage
- Behat
- Packaging
- Test deploy

Try [Scrutinizer](https://scrutinizer-ci.com/) or [Exakat](https://www.exakat.io/)
[on Debian](https://exakat.readthedocs.io/en/latest/Installation.html#quick-installation-with-debian-ubuntu)

### Workflow in git

- New feature or fix is ready and "works for me" -> _PR_ (new branch)
- CI all green -> _dev branch_
- previous feature approved -> _staging branch_ + deploy to staging server
- testing folks approve it -> _master branch_
- wait for release -> tag + build + deploy to production server

Commit checklist:
code, tests, changelog, commit message, issue link, watch CI (in `PULL_REQUEST_TEMPLATE.md`)

[Release checklist](https://make.wordpress.org/cli/handbook/release-checklist/):
tag, build, deploy, announce (Wiki)

### Application environment

- Document everything in `hosting.yml`
- Declare directives, functions, extensions and test them in
  [php-env-check](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/php-env-check.php),
  run in composer.json:pre-install-cmd
- PHP version and extensions also in composer.json:require
- Publish Dockerfile of CI
- Build and deploy script (file permissions)
- Cron jobs and workers
- Check queues in a cron job
- Maintenance mode switch and placeholder page (HTTP/503)
- Generate sitemaps
- File change notification: `siteprotection.sh`
- Manage and monitor application/config/route/view cache and sessions
- Run `git status` hourly
- Send filtered application log hourly
- Logrotate application log
- Local queuing MTA for fast email delivery (SMTP is slow), bounce handling
- Move webserver configuration to vhost configuration
- Redirect removed routes, substitute missing images (URL-s)
- Include Fail2ban triggers at least for 404-s, failed login attempts and hidden form fields (WAF)
- Host a [honey pot](http://www.projecthoneypot.org/faq.php#c)
- Register to webmaster tools (Google, Bing, Yandex)
- Differences of a staging/development environment

### Tips for developing your application

[PSR-1: Basic Coding Standard](http://www.php-fig.org/psr/psr-1/)

> A file SHOULD declare new symbols (classes, functions, constants, etc.) and cause no other side effects,  
> or it SHOULD execute logic with side effects,  
> but SHOULD NOT do both.

- Separate frontend, backend, API, CLI, cron/workers
- Make your frontend a UI for your API :star:
- Comment your source code like a travel guide!
- The less indentation the better code
- Leave environment settings to the server, and check environment (php-env-check.php)
- Move resource-intensive tasks to cron jobs/workers
- Store and calculate dates, times in UTC and display it in the user's timezone
- Develop maintenance (e.g. deploy, import, export) tools for the command line

### Parts of an application

- Autoloading (composer)
- ORM
- Object caching (PSR-6)
- Session handling
- HTTP security and request handling (WAF)
- Input validation, sanitization
- Escaping (SQL, HTML, JavaScript)
- String translation (gettext, pseudo English)
- Content management: large pieces of markup, reusable content blocks
- Internationalization (i18n)
- Templating
- Authentication (2FA)
- User roles and capabilities
- Email addresses, composing and sending
  (plain text version, NeverBounce, mailcheck.js, form spam, obfuscate email addresses)
- Document generation (PDF, Excel, image)
- Image management (Cloudinary)
- Static asset management (building, versioning) and loading
- Analytics, visitor tracking

### Maintenance

Have me on board: viktor@szepe.net
