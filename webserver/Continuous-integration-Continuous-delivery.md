# Continuous integration and Continuous delivery

How to design and implement CI and CD.

### CI

- Run in a premade container or install packages
- Display environment information
- Access credentials
- Cache OS and language library packages
- Check package management configuration
- Check outdated packages and known security vulnerabilities
- Configure application
- Lint code
- Lint template files
- Do static analysis
- Run tests
- Custom checks and warnings
- Code coverage
- Start CD by SSH-ing to own server (restrict,command in authorized_keys and DenyUsers in sshd.conf)
- Wipe sensitive data

### CD

- Constrains: successful tests, specific branch, tag in commit message `[deploy:live]`
- Do not run as root user
- Keep deploy configuration in a file
- Log every output to a file, log start and finish to syslog
- Limit execution time of time-consuming steps (timeout)
- Optionally back up project files before starting to deploy
- Create a bot user for git access with SSH key (@companybot)
- Detect changes in current project files
- Turn on maintenance mode (HTML, static file, AJAX and API requests)
- Disable cron jobs and background workers
- Clear caches (configuration, routes, application, template etc.)
- Identify git repository and branch
- Checkout by commit hash (not branch HEAD)
- At least **lint the source code**
- Don't deploy testing packages
- Enable production optimizations in package manager
- Build code
- Run database migrations
- Turn off maintenance mode
- Populate caches
- Run at least 1 basic functional or unit test (e.g. log in or display dashboard)
- Check HTML output
- Special sudo configuration for reloading php-fpm
- Send email, Slack or Trello notification
