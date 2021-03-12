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
- Have a fixed time frame for paying back technical debt
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
- Consistent indentation
- LF lineends
- UTF-8 encoding without BOM
- **Trim trailing whitespaces**
- Insert final newlines
- Non-ASCII characters (emoji, accented letter, signs) `LC_ALL=C grep -P '[\x80-\xFF]'`

[EditorConfig](/.editorconfig),
[PSR12 ruleset](https://github.com/squizlabs/PHP_CodeSniffer/blob/master/src/Standards/PSR12/ruleset.xml)

### Use others' work :exclamation:

- Declare class, method and variable naming, consider [PSRs](http://www.php-fig.org/psr/)
- Frameworks/CMS-s
- Packages/Libraries
- SaaS (Loco, Paperplane)
- Unified email, calendar, contacts API (Nylas)
- Development tools ([Vagrant](https://app.vagrantup.com/laravel/boxes/homestead),
  [Laragon](https://laragon.org/))
- Testing tools ([CI](/webserver/Continuous-integration-Continuous-delivery.md))
- Build and [deployment](/webserver/Continuous-integration-Continuous-delivery.md) tools (CD)
- Changelog (Headway)
- Application performance and error monitoring (Checkly)

### Workflow in git :octocat:

- New feature or fix is ready and "works for me" → _PR (new branch)_
- → CI all green → _dev branch_
- → Previous feature approved → _staging branch_ + deploy to staging server :ship:
- → Testing folks approve it → _master branch_
- → Wait for release → tag and deploy to production server :ship:

Commit checklist:
code, tests, changelog, [commit message](https://conventionalcommits.org/)
with [emojis :bug:](https://gitmoji.carloscuesta.me/),
issue link, watch CI (`PULL_REQUEST_TEMPLATE.md`)

[Release checklist](https://make.wordpress.org/cli/handbook/release-checklist/):
tag, build, deploy, announce (blog, email, Wiki)

### Hotfix flow :boom:

- Catastrophe → _hotfix branch_ + deploy to production server :ship:
- Alert (email, chat, SMS)
- Watch logs
- Merge changes to _dev branch_

### CI outside tests :mag:

What to include in continuous integration with 0% code coverage?
(no unit tests, no functional test)

Use Docker **containers** for testing.

- Modern task runner (composer:scripts, consolidation/robo, npm:scripts, grunt, gulp)
- Parallel package installation (hirak/prestissimo)
- Git hook integration (phpro/grumphp)
- Parallel syntax check (php-parallel-lint)
- PSR-12-based coding style (phpcs)
- Warn on `TODO` and `FIXME`: "Move it into issues!" (phpcs)
- PHP Compatibility check (phpcompatibility/php-compatibility)
- [PHPDoc checker](https://github.com/odan/docblock-checker)
- [Static analysis](https://www.youtube.com/watch?v=majpU-_ShB0) (phpstan, larastan, psalm, phan)
- Mess Detector (phpmd) rules: clean code, code size, controversial, design, naming, unused code
- Critical vulnerabilities in dependencies (sensiolabs/security-checker, roave/security-advisories, dependencies.io)
- Build assets (webpack)
- Metrics (phpmetrics, phploc, laravel-stats)

### CI with tests :mag_right:

- PHPUnit
- Measure code coverage
- Codeception, Behat, [KantuX](https://a9t9.com/kantu)
- Packaging
- Test deploy

Try [Scrutinizer](https://scrutinizer-ci.com/) or [Exakat](https://www.exakat.io/)
[on Debian](https://exakat.readthedocs.io/en/latest/Installation.html#quick-installation-with-debian-ubuntu)

### Testing tools :pick:

- Performance (Tideways, Blackfire)
- Security scanner (Netsparker, Ripstech, StackHawk, [awesome-php-security](https://github.com/guardrailsio/awesome-php-security#readme))
- [Laravel Analyzer](https://laravelshift.com/)

### Tips for developing your application :bulb:

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
- [DI containers](https://www.php-fig.org/psr/psr-11/meta/#8-implementations)
- Exception handling
- Logging
- ORM
- Database migration
- Application caching aka. object cache ([PSR-6](https://github.com/php-cache/illuminate-adapter))
- HTTP communication (request, response, routes) and security (URL structure, WAF)
- Session handling (very long sessions, CSRF,
  session expiration UX: timer, warning, redirect, password input)
- Form handling, input validation, sanitization
  (UserFrontValidate->Request->BackendValidate->BusinessLogic->Response)
- Escaping (SQL, HTML, URL, JavaScript)
- Internationalization
  and [localization](https://www.gnu.org/savannah-checkouts/gnu/libc/manual/html_node/Locale-Categories.html)
  (PHP, JavaScript, language, [time zone](http://google.com/search?q=Jon+Skeet+date+time),
  calendar, number formats and units, string collation),
  string translation (gettext, pseudo English)
- Content management: large pieces of markup, reusable content blocks
- Templating
- Authentication (Web Authentication API, client certificate, 2FA,
  [password security](/security/Password-security.md), lock session to IP address)
- Ability of matching an event (uncaught exception) to a user ID or session
- User roles and capabilities
- Email addresses, composing and sending
  ([maximum length](https://tools.ietf.org/html/rfc5321#section-4.5.3.1),
  obfuscate email addresses, hidden field in form, mailcheck.js, plain text version, NeverBounce)
- Document generation (CSV, [PDF](https://www.paperplane.app/), Excel, image)
- Image management (Cloudinary, https://blurha.sh/ )
- Maintenance mode switch and placeholder page (HTTP/503)
- Static asset management (building, versioning) and loading
- Search experience
- [Keep A Changelog](https://github.com/phly/keep-a-changelog)
- Analytics, visitor tracking (HEAP, Hotjar, Smartlook, Clicktale)
- Performance (application monitoring, New Relic)
- [Error tracking](https://github.com/getsentry/sentry): JavaScript, PHP, queue, cron (no overlapping)

### Application environment

- Document everything in `hosting.yml`
- Declare PHP version, extensions, directives, functions and test them in
  [php-env-check](/webserver/php-env-check.php),
  run in composer.json:pre-install-cmd,
  **PHP version** and extensions also in composer.json:require
- Have an update policy for PHP, framework, packages
- Set environment variables (PHP-FPM pool, `.env`)
- Publish Dockerfile of CI (GitLab Container Registry, Docker Hub)
- Build and deploy script (file permissions)
- Cron jobs and queues (check periodically, email sending and time consuming tasks,
  catch SIGTERM on system shutdown `pcntl_signal(SIGTERM, 'signal_handler');`)
- Generate sitemaps
- File change notification: `siteprotection.sh`
- Manage and monitor application/config/route/view cache and sessions
- Run `git status` hourly
- Report application log extract hourly (recipients)
- Rotate application log
- Move per-directory webserver configuration to vhost configuration
- Redirect removed routes, substitute missing images (URL-s)
- Use queuing MTA for fast email delivery (external SMTP is slow), bounce handling
- Include firewall/Fail2ban triggers at least for: 404-s, failed login attempts, hidden form fields (WAF)
- Host a [honey pot](https://www.projecthoneypot.org/faq.php#c)
- Register to webmaster tools (Google, Bing, Yandex)
- Match production/staging/development/local environments (Docker, php-env-check)

### Differences of production and non-production environments :gear:

- Environment examples: development, staging, beta, demo
- Different domain name (SLD)
- Disallowing robots.txt
- Different Apache configuration
- Different PHP extensions and directives (`opcache.validate_timestamps`)
- Alternative email delivery
- Modified application configuration (environment name, debug logging)
- Change crypto salts, regenerate password hashes
- Disable/use another CDN
- Disable/switch to sandbox mode in 3rd party integrations (analytics, chat, performance monitoring, payment gateway)
- Disable automatic updates
- Stop cron jobs
- Visually distinguish non-production sites

#### Visual signals of a non-production environments

- Change favicon to an animated GIF image
- Tag page title `<title>[STAGING] $page_title</title>`
- Add a flashy line `#MainMavigation { border-top: 3px dashed magenta; }`
- Surround/invert the company logo `#BrandLogo { outline: 3px dotted magenta; }`
- Change background color of WordPress admin bar

### Login and Sign up page features :door:

- Logo and title
- Language selector
- [News](https://app.cloudcannon.com/users/sign_in) or [marketing message](https://www.gosquared.com/join/analytics/)
- "Remember me" checkbox
- "Forgot password" link
- Login and Sign up page linking each other
- Direct registration on login page: email field and signup button
- SSO
- Privacy Policy and Terms of Service links
- Support email and [chat/open ticket](https://voximplant.com/solutions/dialogflow-connector)
- Marketing message on ["logged out" pages](https://sendgrid.com/logged-out/)

### Authentication :key:

- Analyze HTTP headers
- Browser check with JavaScript
  ([proof-of-work](https://en.wikipedia.org/wiki/Proof-of-work_system#List_of_proof-of-work_functions))
- Client-side [email address check](https://github.com/mailcheck/mailcheck)
- Suspicious email address:
    - company domain
    - blocked domain (e.g. example.com, *.test)
    - disposable address
    - non-existent domain
    - missing MX
    - unresolvable MX
- Blocked usernames
- Force [strong passwords](/security/Password-security.md):
    - previously used
    - on most common passwords list
    - similarity to name, username or other user details
    - length
    - complexity
    - xkcd password strength
    - _pwned_ password
- Provide 2FA (TOTP, SMS, email), encourage users to use KeePass
- Use [Argon2 hashing](https://wiki.php.net/rfc/argon2_password_hash) `password_hash($pwd, PASSWORD_ARGON2I)`
- Wipe the plaintext password from memory
- Login security: lock sessions to, and allow login from
    - 1 IP address (IPv4, IPv6)
    - In an IP range (e.g. a /24 network)
    - Within 1 AS (autonomous system) thus inside an ISP
    - Within multiple AS-es (mobile roaming)
    - Within a country
    - Within a region/timezone (multiple countries)
    - Within a continent
    - Same user agent strings
    - Same device (user agent strings) with upgrades (device, OS, browser)
    - Allow/deny multiple (how many?) sessions
    - Session timeout
    - Authorize IP address procedure
    - Login notification
    - New device notification
    - Login logging or last successful login logging
- Inactive accounts
- [Authentication as a Service](https://auth0.com/rules/thisdata-alert-anomalies)
- [Authentication system](https://www.arkoselabs.com/technology)
- If you choose an [identity provider](https://www.lastpass.com/products/identity)
  search the web for its name plus "breach" "exploit" "security"

### Email address lifecycle

- `form` analyze HTTP request
- `form` hidden field in form
- `input` maximum length
- `input` mailcheck.js
- `input` Suspicious email address
- `input` NeverBounce
- `output` obfuscate email addresses
- `delivery` prevent automatic responses
- `delivery` detect bounce -> take action (stop sending, notify user or user's team)

### User support, user feedback

List: https://www.g2crowd.com/categories/help-desk

Multilingual support.

- [Aquire, engage and support](https://www.intercom.com/)
- [Track feedback](https://canny.io/)
- [Slack-based Customer Service App](https://get.slaask.com/)

#### Login problems

- Password reminder
- Ask for a new password
- Get help (see _Logged in_ section)
- Suggest a password manager (avoid saving passwords to browser)
- Short [video about password](https://www.youtube.com/watch?v=XchWBCZSOt0) and cybersecurity
- Signing in on an old login page (reopened by the browser) with expired cookies
- Login to a specific page (inside the application) through the login page
- Custom messages on each failed login attempt, automatic redirect to password reminder page

#### Logged in

- [Open ticket](https://www.ladesk.com/)
- Start online chat
- Search knowledge base (help articles)
- [Take a screenshot](https://doorbell.io/)
- Send attachments
- General feedback, bug reporting
- [Record](https://logrocket.com/) [sessions](https://www.sessionstack.com/)

### Maintenance :wrench:

Have me on board: viktor@szepe.net

*These lists are theory-free! All of them were real-life problems.*
