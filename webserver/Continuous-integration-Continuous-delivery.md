 # Continuous integration and Continuous delivery

How to design and implement CI and CD.

### CI

- Run in a premade container or install packages
- Display environment information
- Set access credentials
- Cache OS and language library packages
- Check package management configuration
- Check outdated packages and known security vulnerabilities
- Build code
- Configure application
- Lint source code
- Lint template files
- Check coding style
- Do static analysis
- Run tests
- Custom checks and warnings
- Measure code coverage
- Start CD by SSH-ing to own server (`restrict,command` in authorized_keys and `DenyUsers` in sshd.conf)
- Wipe sensitive data

### CD

- Constrains:
  * successful tests
  * do not run on PR-s
  * our repo
  * specific branch
  * tag in commit message `[deploy:live]`
  * deploy head commit only
  * optional manual start ([GitLab manual actions](https://gitlab.com/help/ci/yaml/README.md#manual-actions))
- Do not run as root user
- Keep deploy configuration in a file
- Log every output to a file, log start and finish to syslog
- Limit execution time of time-consuming steps (timeout)
- Optionally back up project files before starting to deploy
- Create a bot user on the server for git access with SSH key (@companybot)
- List changes in current project files
- Turn on [maintenance mode](https://github.com/laravel/framework/blob/18402cd4b83fd1d944f3baa0d8cc26d7dfcce333/src/Illuminate/Foundation/Application.php#L927-L930)
  covering static resource, page, AJAX and API requests
- Disable cron jobs and background workers (email piped to a program)
- Clear caches (configuration, routes, application, template etc.)
- Identify git repository and branch
- Checkout by commit hash (not by branch HEAD)
- At least **lint the source code**
- Don't deploy testing packages
- Enable production optimizations in package manager
- Build code
- Run database migrations
- Turn off maintenance mode
- Populate caches
- Run at least 1 basic functional or unit test (e.g. log in or display dashboard)
- Check HTML output
- Special sudo configuration for reloading PHP-FPM
- **Alert on failure**
- Send email, Slack or Trello notification
