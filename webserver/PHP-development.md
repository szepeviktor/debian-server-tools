# PHP development notes

How to keep our codebase clean?

See an article on [Moving Fast With High Code Quality](https://engineering.quora.com/Moving-Fast-With-High-Code-Quality)
and [clearPHP rules](https://github.com/dseguy/clearPHP)

### Forces influencing development

- First an foremost keeping the codebase clean to avoid rewrites in the far future
- Make profit!
- Move fast with development, use no tools that slows down development
- Keep developer morale high
- Think about the far future when making decisions today

### Editor settings

Bytes and whitespaces.

[PSR-1: Basic Coding Standard](http://www.php-fig.org/psr/psr-1/)

> A file SHOULD declare new symbols (classes, functions, constants, etc.) and cause no other side effects,
> or it SHOULD execute logic with side effects,
> but SHOULD NOT do both.

- UTF-8 encoding without BOM
- LF lineends
- One kind of indentation
- **Strip trailing spaces**

### Use others's work

- Consider [PSR-s](http://www.php-fig.org/psr/)
- Frameworks/CMS-s
- Packages/Libraries (composer)
- SaaS
- Development tools
- Deployment tools
- Application monitoring

### CI outside tests

What to include in continuous integration with 0% coverage?
(no unit tests, no functional test)

- Syntax (php-parallel-lint)
- Coding style (PSR-2, phpcs)
- Warn on moving `TODO` and `FIXME` into issues (phpcs)
- Static analysis (phpstan, phan)
- Mess Detector (phpmd)
- Critical vulnerabilities in dependencies (Gemnasium)
- Metrics (phpmetrics)
- Build assets (grunt)

### CI with tests

- PHPUnit
- Measure code coverage
- Behat
- Packaging
- Test deploy

Try [Scrutinizer](https://scrutinizer-ci.com/) or [Exakat](https://www.exakat.io/)
https://exakat.readthedocs.io/en/latest/Installation.html#quick-installation-with-debian-ubuntu

### Tips for structuring your application

- Comment your source code like a travel guide!
- The less indentation the better code
- Make your frontend a UI for your API :star:
- Separate frontend, backend, API, cron/workers
- Move resource-intensive tasks to cron
- Store and calculate dates, times in UTC and display it in the user's timezone

### Parts of an application

- ORM
- Object caching (PSR-6)
- Session handling
- HTTP security and request handling
- Input validation, sanitization
- Escaping (SQL, HTML, JavaScript)
- String translation (gettext)
- Content management: large pieces of markup, reusable content blocks
- Internationalization (i18n)
- Templating
- Authentication
- User roles and capabilities
- Email composing and sending
- Document generation (PDF, Excel, image)
- Image management
- Static asset management
