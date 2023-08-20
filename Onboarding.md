# Infrastructure and application setup for new clients

*Welcome to the process of setting up your infrastructure and your application!*

![Page HTML load time](/.github/assets/Page-html-load-time.png)

Details about [running your web application](https://git.io/vNryB)

### Requirements

1. **2-4 hours of time**
1. One person able to consider things, decide and act at every provider
    1. Finances
    1. User management
    1. Managing services
    1. Contacting support
    1. Reacting to notifications
1. If moving: access to accounts at all providers below
1. Company details (registered name, registration number, address)
1. Access to company email account
1. Access to company bank card including CVC and 3-D Secure device
1. Access to company phone
1. Installed 2FA mobile or desktop app

### Specialized infrastructure providers

One per category.

1. Domain registrar:
   **Gandi :eu:, AWS, Name.com by Donuts, Hexonet by CentralNic, Rackhost/.hu :eu:**
1. DNS provider with [DNSSEC](https://www.icann.org/news/announcement-2019-02-22-en):
   **AWS, HE, [Google](https://cloud.google.com/dns/pricing), Exoscale :eu:, Gandi :eu:**
1. Server provider:
   **UpCloud :eu:**
1. SSL certificate vendor for HTTPS:
   **[Cheapsslsecurity.com](https://cheapsslsecurity.com/rapidssl/rapidsslcertificate.html),
   [SSLMate](https://sslmate.com/),
   DigiCert,
   Certum :eu:,
   [Buypass](https://www.buypass.com/products/tls-ssl-certificates) :eu:**
1. CDN provider:
   **AWS, KeyCDN :eu:, Akamai from Selectel**
1. Transactional email provider:
   **AWS, SparkPost, SparkPost EU :eu:**
1. Storage provider:
   **AWS, UpCloud :eu:, Backblaze B2, Selectel, Oktawave :eu:**

[.hu domain regisztrátorok](https://www.domain.hu/regisztratorok/)

[Google Cloud Platform Premium Support for $100/mo](https://cloud.google.com/support/?options=premium-support#support-options)

[AWS Europe invoicing](https://aws.amazon.com/legal/aws-emea/)

[AWS certificates for internal usage only](https://aws.amazon.com/certificate-manager/faqs/#general)

[AWS CloudFront supports TLS 1.3](https://aws.amazon.com/about-aws/whats-new/2020/09/cloudfront-tlsv1-3-support/)

### Policy for user accounts at service providers

- Who is the legal owner of the account?
- Who has access to this account?
- Do we share account passwords?
- Do main accounts have 2FA?
- What other non-relevant services are under this account?
- Accounts for domain registration and DNS services must use an email address with a different domain name.
- Is the email account/phone number/bank card of this account in daily use?
- Use a virtual bank card with a sub account instead of a physical bank card tied to the main bank account!

### Secure browser in an ephemeral cloud instance

This section contains preparations for secure registration.

- Deploy [Windows Server 2016 Standard instance](https://hub.upcloud.com/server/create)
- Finish installation on the console: set language
- Log in as `Administrator` with
  [RDP on Windows](https://ci.freerdp.com/job/freerdp-nightly-windows/arch=win64,label=vs2013/)
  or [RDP on Mac](https://itunes.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- Download [Palemoon browser](https://www.palemoon.org/download.php?mirror=eu&bits=64&type=installer)
- Create UpCloud shortcut on the Desktop: `palemoon.exe "https://www.upcloud.com/register/?promo=U29Q8S"`
- Create AWS shortcut: `"https://portal.aws.amazon.com/gp/aws/developer/registration/index.html"`
- Download [`user.js`](https://github.com/szepeviktor/windows-workstation/blob/master/upcloud/user.js) to `%APPDATA%\Moonchild Productions\Basilisk\Profiles\`
- Open On-Screen Keyboard for entering passwords
- Use the browser
- Delete the instance

### UpCloud registration

- Referral URL
- [KeePass](https://keepass.info/) is an open source password manager
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- My Account / Billing / MANUAL
- My Account / Billing / AUTOMATED / Credit Card drop-down
- Servers / Deploy a server / Add SSH public key
- Check IP reputation (Security Trails, Project Honey Pot, HE BGP Toolkit, AbuseIPDB)
- Servers / Server listing / (server name) / IP ADDRESSES / REVERSE DNS NAME Public IPv4 + IPv6
- Log out (prevent session hijacking)
- Have support enable **SMTP** for the account
- Document server IP

### Amazon Web Services registration

- https://aws.amazon.com/
- [KeePass](https://keepass.info/) is an open source password manager
- Account type: Business
- Verification phone call: dial numbers
- Support Plan: Basic
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- Billing preferences / Disable Free Tier Usage Alerts + Enable Billing Alerts
- CloudWatch / Select Region `us-east-1` / Alarms / Create Alarm for EstimatedCharges
- Route53 / Domain + DNS
- CloudFront / CDN
- SES / Domain + SMTP credentials +
  [Move Out of the Sandbox](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html) +
  Bounce notification
- S3 / Server backup bucket
- IAM / Route53 API user + CloudFront API user + S3 API user
- Log out (prevent session hijacking)
- Document credentials

### Cheapsslsecurity.com registration

[RapidSSL DV](https://cheapsslsecurity.com/rapidssl/rapidsslcertificate.html)

- Buy Multiple Years: 2 Year
- Billing Address, Payment Method

[Dashboard](https://cheapsslsecurity.com/client/ordersummary.html)

<kbd>Generate Cert Now</kbd>

- (1) **Select Your Order Type:** select New **or** Renewal
- (2) **Input CSR:** paste code block
- (3) **Prove control over your domain:** select DNS TXT
- (4) **Choose domain validation level:** select base domain
- (5) **Contact Information:** enter your contact info
- (6) **Additional Certificate Options:** Server Platform: select Other
- (7) **Certificate Services Agreement:** tick both checkboxes `[x]` `[x]`

Verify your URL

- Check domain name
- Set TXT record in DNS
- Wait for issuance

:bulb: Only ASCII characters in name and address.

[Dashboard / Manage Renewal Email Preferences](https://cheapsslsecurity.com/client/renewalemail-preferences.html)

- Select Admin/Technical contact: untick both checkboxes `[ ]` `[ ]`

##### Renew a certificate

[Dashboard](https://cheapsslsecurity.com/client/ordersummary.html)

- (_select the certificate_)
- <kbd>RENEW</kbd>

### Email delivery

- There is no guaranteed email delivery on the Internet
- :man: :incoming_envelope: :man_office_worker: [ESP](https://2fa.directory/#email) for *One-to-One* emails including inbound messages:
  **Google Workspace, [Protonmail :eu:](https://protonmail.com/signup), [Почта Mail.Ru](https://biz.mail.ru/mail/), [DomainFactory :eu:](https://www.df.eu/int/e-mail-hosting/)**
  <!-- not Tiliq -->
- File sharing, large file sending: [WeTransfer :eu:](https://wetransfer.com/),
  [pCloud :eu:](https://transfer.pcloud.com/),
  [Smash :eu:](https://fromsmash.com/)
- :robot: :incoming_envelope: :woman_office_worker: *Transactional* emails and notification emails for alerts, log excerpts:
  [see providers above](#specialized-infrastructure-providers)
- :man: :incoming_envelope: :man_office_worker::older_man::woman_mechanic: *Bulk* email for newsletter: customer relations with [Intercom](https://www.intercom.com/)
- Bounce messages for **all three** email types
- Sender fraud protection and content integrity for **all three**: SPF, DKIM, DMARC
- Outbound spam protection: [MailChannels](https://www.mailchannels.com/pricing/)
- My email address: `webmaster@`
- Teamwork in one Gmail inbox: [Drag](https://www.dragapp.com/)

### Infrastructure setup

- Document in hosting.yml and server.yml (Skype, `Ugyfelek.yml`, KeePass)
- Gain access to providers (web based sub-account or API)
- Manage migrations (`magic-wormhole`, WeTransfer.com)
- PTR/IPv4, PTR/IPv6 records
- Domain locking and autorenew
- DNS records (check, clean up, monitor)
- Incoming ESP and bounce notification
- Whitelisted IP-s (office)

### Application setup

- **Development providers/accounts**, e.g. hosted git, issue tracker (document, gain access, set up), mail trap
- Git repository, branch usage (git flow)
- 3rd party providers (document, gain access, set up)
- Environments: development, staging, production
- User names and SSH keys
- Purchased plugins and libraries (updates, gain access, support)
- Application environment definition
- Set up CI
- Write deploy script
- Notifications (email, chat, SMS)
- Revenue tracking
- Error tracking
- **Development: development in production?, who has access, where to develop, how to deploy**
- Editorial duties: **who has time and competence**

### Backup

- Data on servers is automatically backed up daily with 7 days rotation
- External resources (S3 bucket)
- Email accounts (local, IMAP)
- Issues ([Clubhouse](https://www.shortcut.com/), Trello, GitHub, GitLab)
- Code repositories (GitLab, GitHub)

### Cyber security

- Please see https://www.privacytools.io/
- Notify on account breach: search email address https://haveibeenpwned.com/
- Notify on account breach: search password https://haveibeenpwned.com/Passwords
- Notify on account breach: search all details https://sec.hpi.uni-potsdam.de/ilc/search
- Enable **OS account security** (fingerprint, face ID, hardware key, password)
- All participants should stop using their browsers to store form data and passwords
- Password authentication workflow
  1. Open the login page in a **new** browser tab
  1. Instruct your password manager to enter credentials and 2FA token
  1. Operate, do not leave your computer/device
  1. After finishing log out
  1. Click lock icon / Delete cookie in the address bar
  1. Close current browser tab
- Data breach prevention in the application: automated attacks, paid hacker
- Protection against malware and phishing attacks (**credential stealing**)
- Against key loggers
- Against mobile malware
- Ransomware mitigation
- Spam filtering
- **Incident response plan** (outage, security incident)
- Yearly security check

### Collaboration

- _No emails if it is possible_
- Issues/ticketing: [Clubhouse](https://www.shortcut.com/) or Trello
- Chat: Slack

### Onboarding for developers

- We run Debian GNU/Linux on an UpCloud cloud instance
- All services run in [UTC timezone](http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html)
- MariaDB or Percona Server + Apache with HTTP/2 and event MPM + PHP-FPM 7 + Redis
  ([full feature list](/debian-setup/debian-setup.sh#L23))
- Every web application (and website) runs as a separate Linux user
- There are no passwords for Linux users, only SSH keys
- All **non-production** servers are accessible through SSH: **terminal, MySQL tunnel, file upload, code deploy** etc.
- Production servers are not accessible for humans (except through HTTPS)
- TCP ports for web and SSH are heavily protected (maxretry=3) [with Fail2ban](/security/fail2ban-conf)
- Source code is kept in git (version-control system)
- PHP OPcache's [file timestamp validation](/webserver/phpfpm-pools/Skeleton-pool.conf#L30) is off,
  thus PHP files are read once at first access, we use [cachetool](https://github.com/gordalina/cachetool)
  to reset OPcache after code change
- There are *standard* directories for [sessions, upload and tmp](/webserver/phpfpm-pools/Skeleton-pool.conf#L36-L38)
- `.htaccess` files are disabled, Apache rules should be in vhost configuration (it is faster)
- File versioning is not in query string but turned into file names like `filename.002.ext` in URL-s,
  [an Apache rule](/webserver/apache-sites-available/Skeleton-site-ssl.conf#L155-L156) reverts them
- Your web application is protected by a [WAF](https://github.com/szepeviktor/waf4wordpress)
- Blacklisted things:
  FTP/S protocol,
  web-based administration (import, export, backup, cPanel, phpMyAdmin),
  POP3/S protocol
- How to design and implement [CI and CD](/webserver/Continuous-integration-Continuous-delivery.md)
- [Running a Laravel application](https://github.com/szepeviktor/running-laravel)
- [WordPress lifecycle](https://github.com/szepeviktor/wordpress-website-lifecycle)
- Interesting read on [web applications](/webserver/PHP-development.md)
