# Getting to know new clients

[![hu](https://img.shields.io/badge/nyelv-magyar%20%F0%9F%87%AD%F0%9F%87%BA-white)](Onboarding-business2.md)
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
    or [email automation](https://help.clubhouse.io/hc/en-us/articles/206093065-Setting-Up-Zapier-Integrations)
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

1. Nem kívánt dolgok megsokasodása
1. Kívánt dolgok elmaradása

- Bevétel követés
- Új regisztrációk, előfizetési csomag választás
- Konverziók
- Az alkalmazásban létrehozott aktorok darabszáma

* Commit-ok darabszáma
* Kinyitott és lezárt hibajegyek darabszáma
* Hibanapló hossza
* Hálózati forgalom
* Támadások száma

Szolgáltató: https://amplitude.com/

### Szerkesztő képességei

1. Tipográfiai alapismeretek
1. WYSIWYG szerkesztő profi használata
1. Tartalom életciklusának megtervezése, kivitelezése
1. SEO alapismeretek
1. Az URL részeinek ismerete
1. Saját bejövő linkek készítőivel való kapcsolat (pl. Facebook menedzserrel)
1. Képek és média életciklusának ismerete
1. Képek előfeldolgozása
1. Beszédes fájlnevek adása

## Kódolási büdzsé

Egy fő back-end és egy fő front-end fejlesztő
**olcsóbb**, gyorsabb és jobb munkát végez, mint egy fő.

- Specifikáció
- Technológiák kiválasztása
- Kód tervezés (architektúra)
- Grafikai dizájn és UX
- [MVP](https://en.wikipedia.org/wiki/Minimum_viable_product)
- Funkciók befejezése (az MVP-n felül)
- Kézi tesztelés
- Hiba javítás

### Technikai tartozás (technical debt)

https://twitter.com/StepsizeHQ/status/1156582846057844736

- Dokumentumok frissítése
- Hiba kezelés (hiba kontextus, könnyű felderíthetőség) :point_right: ettől tönkremennek a cégek
- Biztonság (security) növelése
- Kód kommentelés (docblock, üzleti logika és a commit üzenetek is)
- Kódolás nélküli (zero coverage) tesztek futtatása
- Egység (unit) és funkcionális tesztek írása
- Keretrendszer és csomag frissítés
- `TODO` és `FIXME` kommentek keresése a forráskódban
- Refaktorálás
