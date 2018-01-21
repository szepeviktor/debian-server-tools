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

### High level overview

- Software architecture :sunny: :sunny: :sunny:
- Documented **code design** :sunny: :sunny:
- Implementation (source code writing) :sunny:
- Automatic and manual testing
- Periodic code review, security audit

### Editor settings

Bits and bytes.

- Execute bit off
- UTF-8 encoding without BOM
- LF lineends
- Consistent indentation
- **Strip trailing spaces**

[PSR2 ruleset](https://github.com/squizlabs/PHP_CodeSniffer/blob/master/src/Standards/PSR2/ruleset.xml)

### Use others' work :exclamation:

- Consider [PSR-s](http://www.php-fig.org/psr/)
- Frameworks/CMS-s
- Packages/Libraries
- SaaS
- Development tools (Vagrant)
- Testing tools (CI)
- Build and deployment tools
- Application monitoring (performance, errors)

### Workflow in git :octocat:

- New feature or fix is ready and "works for me" → _PR (new branch)_
- → CI all green → _dev branch_
- → Previous feature approved → _staging branch_ + deploy to staging server :ship:
- → Testing folks approve it → _master branch_
- → Wait for release → tag and deploy to production server :ship:

Commit checklist:
code, tests, changelog, commit message, issue link, watch CI (`PULL_REQUEST_TEMPLATE.md`)

[Release checklist](https://make.wordpress.org/cli/handbook/release-checklist/):
tag, build, deploy, announce (Wiki)

### Hotfix flow :boom:

- Catastrophe → _hotfix branch_ + deploy to production server :ship:
- Alert (email, chat, SMS)
- Watch logs
- Merge changes to _dev branch_

### CI outside tests :mag:

What to include in continuous integration with 0% code coverage?
(no unit tests, no functional test)

Use Docker **containers** for testing.

- Modern task runner (composer:scripts, consolidation/robo, npm only, grunt, gulp)
- Parallel package installation (hirak/prestissimo)
- Git hook integration (phpro/grumphp)
- Parallel syntax check (php-parallel-lint)
- PSR-2-based coding style (phpcs)
- Warn on `TODO` and `FIXME`: "Move it into issues!" (phpcs)
- [Static analysis](https://www.youtube.com/watch?v=majpU-_ShB0) (phpstan, psalm, phan)
- Mess Detector (phpmd) rules: clean code, code size, controversial, design, naming, unused code
- Critical vulnerabilities in dependencies ([Gemnasium](https://gemnasium.com/), dependencies.io)
- Metrics (phpmetrics)
- Build assets (webpack)

### CI with tests :mag_right:

- PHPUnit
- Measure code coverage
- Codeception, Behat
- Packaging
- Test deploy

Try [Scrutinizer](https://scrutinizer-ci.com/) or [Exakat](https://www.exakat.io/)
[on Debian](https://exakat.readthedocs.io/en/latest/Installation.html#quick-installation-with-debian-ubuntu)

### Tips for developing your application

[PSR-1: Basic Coding Standard](http://www.php-fig.org/psr/psr-1/)

> A file SHOULD declare new symbols (classes, functions, constants, etc.) and cause no other side effects,  
> or it SHOULD execute logic with side effects,  
> but SHOULD NOT do both.

- Separate frontend, backend, API, CLI, cron/queue
- Make your frontend a UI for your API :star:
- Comment your source code like a travel guide!
- The less indentation the better code
- Leave environment settings to the server, and check environment (php-env-check.php)
- Move resource-intensive tasks to cron jobs/queues
- Store and calculate dates, times in UTC and display it in the user's timezone
- Develop simple maintenance tools (e.g. deploy, import, export) for the command line

### Parts of an application

- Autoloading (composer)
- ORM
- Application caching aka. object cache ([PSR-6](https://github.com/php-cache/illuminate-adapter))
- HTTP security and request handling (WAF)
- Session handling
- Input validation, sanitization
- Escaping (SQL, HTML, JavaScript)
- Internationalization (PHP, JavaScript)
- String translation (gettext, pseudo English)
- Content management: large pieces of markup, reusable content blocks
- Templating
- Authentication (2FA, password security, lock session to IP address)
- User roles and capabilities
- Email addresses, composing and sending
  (plain text version, NeverBounce, mailcheck.js, form hidden field, obfuscate email addresses)
- Document generation (CSV, PDF, Excel, image)
- Image management (Cloudinary)
- Maintenance mode switch and placeholder page (HTTP/503)
- Static asset management (building, versioning) and loading
- Analytics, visitor tracking (HEAP, Hotjar, Clicktale)
- Performance (application monitoring, New Relic)
- Error tracking (PHP, JavaScript)

### Application environment

- Document everything in `hosting.yml`
- Declare PHP version, extensions, directives, functions and test them in
  [php-env-check](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/php-env-check.php),
  run in composer.json:pre-install-cmd
- **PHP version** and extensions also in composer.json:require
- Set environment variables (PHP-FPM pool, `.env`)
- Publish Dockerfile of CI (GitLab Container Registry)
- Build and deploy script (file permissions)
- Cron jobs and queues (check periodically, email sending and time consuming tasks)
- Generate sitemaps
- File change notification: `siteprotection.sh`
- Manage and monitor application/config/route/view cache and sessions
- Run `git status` hourly
- Email filtered application log hourly (recipients)
- Rotate application log
- Move per-directory webserver configuration to vhost configuration
- Redirect removed routes, substitute missing images (URL-s)
- Use local queuing MTA for fast email delivery (SMTP is slow), bounce handling
- Include Fail2ban triggers at least for: 404-s, failed login attempts, hidden form fields (WAF)
- Host a [honey pot](http://www.projecthoneypot.org/faq.php#c)
- Register to webmaster tools (Google, Bing, Yandex)
- Match production/staging/development/local environments (Docker, php-env-check)
- Differences of a **staging/development** environment (different domain name, robots.txt, email delivery, disable 3rd parties)

### Maintenance :wrench:

Have me on board: viktor@szepe.net

*These lists are theory-free! All of them were real-life problems.*
