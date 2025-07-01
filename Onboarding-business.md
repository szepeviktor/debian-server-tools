# Getting to know new clients

[![hu](https://img.shields.io/badge/nyelv-magyar%20%F0%9F%87%AD%F0%9F%87%BA-white)](Onboarding-business-HU.md)
[![en](https://img.shields.io/badge/lang-English%20%F0%9F%87%AC%F0%9F%87%A7-white)](Onboarding-business.md)

## Process of making a web application

It is highly important to write down in advance what we will do.
Do not make big decisions while writing source code.

1. Discover
1. Define
1. Design
1. Develop

- https://web.archive.org/web/20210517140355/https://www.fps.hu/work (fps)
- https://web.archive.org/web/20181228074713/http://kozpontbanazember.hu/ (FrancisKodak)
- https://www.google.hu/search?q=user+interview+site%3Ahu

### What services do you need?

- Is there a target for the number of sessions per day? (1000/day)
- Will the money coming from users cover the operating costs?
- Will someone touch the production environment?
- Who cover the following areas of expertise?
    - Bridge between managing people and software production (leader)
    - Managing service provider accounts and being in contact with service providers (administration)
    - Software architecture and documentation
    - UI/UX design and documentation
    - Back-end development
    - Front-end development
    - Automated and manual testing
    - Content management
- Web server installation and maintenance
- Defining the application
- Designing the application
- Developing the application
- Define + Design + Develop execution
    1. There will be no such phase or it will be mixed with another one
    1. It will be done by people who are not experts in the phase
    1. We hire freelancer experts
    1. We hire an employee
- Running the application
- Following development and sending PR-s
- Crisis management
- Teaching non experts, reasoning _best practices_
- Reading emails, attending meetings regularly

## Organizing a company

Additions to [Onboarding](/Onboarding.md).

- [Cybersecurity](/Onboarding.md#cyber-security) on every device
    and second opinion behavioral scanner installation (HitmanPro.Alert)
- Introducing a password manager for everyone
- Keeping the company phonebook up to date
- Setting up rules for internal communications
- Project Manager
    - How to schedule :one: new features, :two: bug fixes and :three: technical debt
    - Is an employee assigned more than 1 task at a time
- Following style guide, brand guidelines
- Onboarding and _Product Tour_ with Intercom
- Real time _Application Dashboard_, data-driven decisions

### Internal communications

Goal: communicate on one common platform, retire email communication.

##### Asynchronous

- Issues (bug reports, feature requests)
- Connecting with outsiders within the platform
    or [email automation](https://help.shortcut.com/hc/en-us/articles/206093065-Setting-Up-Zapier-Integrations)
- File sharing
- Calendar
- Inner knowledge base [Notion](https://www.notion.so/)
- Collaboration in notes and documents (e.g. list of service providers, company phonebook)
- Voice messages [Yac](https://www.yac.com/)

Provider: [Clubhouse](https://www.shortcut.com/)

##### Synchronous

- Chat
- Voice call, conference call
- Video call, screen sharing

Provider: [Slack](https://slack.com/)

##### Other providers

1. https://basecamp.com/

### Application Dashboard

For data-driven business decisions.

1. Proliferation of undesired events
1. Absence of desired events

- Revenue tracking
- New registrations, subscription plan selection
- Conversions
- Number of entities (actors) created within the application

* Number of commits
* Number of opened and closed issue tickets
* Length of the error log
* Network traffic
* Number of attacks

Service provider: https://amplitude.com/

### Editor Skills

1. Basic knowledge of typography
1. Proficient use of WYSIWYG editors
1. Planning and executing the content lifecycle
1. Basic understanding of SEO
1. Understanding the structure of URLs
1. Communication with creators of inbound links (e.g., Facebook manager)
1. Understanding the lifecycle of images and media
1. Preprocessing images
1. Using descriptive file names

## Coding Budget

One dedicated back-end developer and one front-end developer
can produce work that is **cheaper**, faster, and better than a single full-stack developer.

- Specification
- Technology selection
- Code design (architecture)
- Graphic design and UX
- [MVP](https://en.wikipedia.org/wiki/Minimum_viable_product)
- Completing features beyond the MVP
- Manual testing
- Bug fixing

### Technical Debt

https://www.monkeyuser.com/2018/tech-debt/

- Updating documentation
- Error handling (context and traceability) :point_right: this is what ruins companies
- Improving security
- Writing code comments (docblocks, business logic, and commit messages)
- Running tests with zero code coverage
- Writing unit and functional tests
- Updating frameworks and packages
- Searching for `TODO` and `FIXME` comments in the source code
- Refactoring
