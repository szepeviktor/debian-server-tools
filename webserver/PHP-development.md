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

### Use others' work

- Consider [PSR-s](http://www.php-fig.org/psr/)
- Frameworks/CMS-s
- Packages/Libraries
- SaaS
- Development tools (CI)
- Deployment tools
- Application monitoring (performance, errors)

### CI outside tests

What to include in continuous integration with 0% code coverage?
(no unit tests, no functional test)

Use Docker **containers** for testing.

- Modern task runner (consolidation/robo, npm only, grunt, gulp)
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
- Email addresses, composing and sending (plain text version, NeverBounce, mailcheck.js)
- Document generation (PDF, Excel, image)
- Image management (Cloudinary)
- Static asset management (building, versioning) and loading
- Analytics, visitor tracking

### Maintenance

Have me on board: viktor@szepe.net
