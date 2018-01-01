# Project Name with X framework

### Attached files

- vhost.conf
- pool.conf
- logrotate
- database.sql
- database-routines.sql
- .env

### Dependencies

- webserver
- PHP engine
- object cache
- package managers
- CLI tools

### Close sourced libraries

### Cron jobs

- `* * *  * *  /path/to/cli cron:run`
- `* * *  * *  /path/to/cli cron:run`

### Third Party integrations

- service: ID
- service: ID

#### Low priority

- service: ID
- service: ID

### Fresh installation on Production server

- Environment setup
- Source code checkout
- Database seeding
- Create caches

### Release deployment on Production server

- Source code checkout
- Database migration
- Create caches
- Static analysis
- Unit tests
- Functional tests
- Reset OPcache

### New installation on Development/Staging server

- Development container (robots.txt, mailing, caches, cron jobs)
- Source code checkout
- Database seeding
- Create caches

### New installation in Local environment
