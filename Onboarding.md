# Infrastructure and application setup for new clients

*Welcome to the process of setting up your infrastructure and your application!*

![Page HTML load time](/Page-html-load-time.png)

Details about [infrastructure and source code management](https://git.io/vNryB)

### Choose one infrastructure provider

1. Domain registrar: **AWS, Gandi :eu:, noip, dyn, Rackhost/.hu :eu:**
1. DNS provider: **AWS, HE, Cloudflare, [Google](https://cloud.google.com/dns/pricing), Exoscale :eu:, Gandi :eu:**
1. Server provider: **UpCloud :eu:**
1. SSL certificate provider for HTTPS:
   **[Cheapsslsecurity.com](https://cheapsslsecurity.com/rapidssl/rapidsslcertificate.html),
   [SSLMate](https://sslmate.com/), DigiCert, Certum :eu:**
1. CDN provider: **AWS, KeyCDN :eu:**
1. Transactional email provider: **AWS, SparkPost, Mailjet :eu:**
1. Storage provider: **AWS, Backblaze B2, Selectel, Oktawave :eu:**

[.hu domain regisztrátorok](http://www.domain.hu/domain/)

[Google Cloud Platform Premium Support for $150/mo](https://cloud.google.com/support/?options=premium-support#options)

[AWS Europe invoicing](https://aws.amazon.com/legal/aws-emea/)

[AWS certificates for internal usage only](https://aws.amazon.com/certificate-manager/faqs/#general)

### Secure browser in an ephemeral cloud instance

- Deploy [Windows Server 2016 Standard instance](https://my.upcloud.com/server/create)
- Finish installation on the console: set language
- Log in as `Administrator` with
  [RDP on Windows](https://ci.freerdp.com/job/freerdp-nightly-windows/arch=win64,label=vs2013/)
  or [RDP on Mac](https://itunes.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- Download [Basilisk browser](http://eu.basilisk-browser.org/release/basilisk-latest.win64.zip)
- Create UpCloud shortcut on the Desktop: `basilisk.exe "https://www.upcloud.com/register/?promo=U29Q8S"`
- Create AWS shortcut: `"https://portal.aws.amazon.com/gp/aws/developer/registration/index.html"`
- Download [`user.js`](https://github.com/szepeviktor/windows-workstation/blob/master/upcloud/user.js) to `%APPDATA%\Moonchild Productions\Basilisk\Profiles\`
- Open On-Screen Keyboard for entering passwords
- Use the browser
- Delete the instance

### Notify on account breach

https://haveibeenpwned.com/

### UpCloud registration

- Referral URL
- [KeePass](https://keepass.info/) is an open source password manager
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- Use a virtual bank card
- My Account / Billing / MANUAL
- My Account / Billing / AUTOMATED / Credit Card drop-down
- Servers / Deploy a server
- Servers / Server listing / (server name) / IP ADDRESSES / REVERSE DNS NAME Public IPv4 + IPv6
- Document server IP + password

### Amazon Web Services registration

- https://aws.amazon.com/
- [KeePass](https://keepass.info/) is an open source password manager
- Account type: Professional
- Use a virtual bank card
- Support Plan: Basic
- **Enable 2FA** ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2))
- Route53 / Domain + DNS
- CloudFront / CDN
- SES / Domain + SMTP credentials +
  [Move Out of the Sandbox](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html) +
  Bounce notification
- S3 / Server backup bucket
- IAM / Route53 API user + CloudFront API user + S3 API user
- Document credentials

### Infrastructure setup

- Document in hosting.yml and server.yml (Skype, Google Contacts, KeePass, link-torzs)
- Gain access to providers (web based sub-account or API)
- Manage migrations
- PTR/IPv4, PTR/IPv6 records
- DNS records (check, clean up, monitor)
- Incoming ESP and bounce notification
- Whitelisted IP-s (office)

### Application setup

- 3rd parties (document, gain access, set up)
- User names and SSH keys
- Git repository, branch usage (git flow)
- Issue tracker
- Paid plugins, libraries (updates, gain access, support)
- Application environment definition
- Set up CI
- Write deploy script
- Notifications (email, chat, SMS)
- **Development: development in production?, who has access, where to develop, how to deploy**
- Editorial duties: **who has time and competence**

### Email delivery

- [ESP](https://twofactorauth.org/#email) for One-to-One emails including inbound messages
  **G Suite, [Protonmail :eu:](https://protonmail.com/signup), [Почта Mail.Ru](https://biz.mail.ru/mail/)**
- File sharing, large file sending [WeTransfer](https://wetransfer.com/),
  [Send](https://send.firefox.com/), [pCloud :eu:](https://transfer.pcloud.com/)
- Transactional emails, see above
- Notification emails (alerts, log excerpts)
- Bulk email (newsletter)
- Bounce messages for **all types**
- Sender fraud protection and content integrity for **all types**: SPF, DKIM, DMARC
- My email address: `webmaster@`

### Cyber security

- Spam filtering
- Protection against malware and phishing attacks (**credential stealing**)
- Against mobile malware
- Ransomware mitigation
- Data breach prevention (in the application)
- Incident response plan (outage, security incident)

### Onboarding for developers

- We run Debian GNU/Linux on an UpCloud cloud instance
- MariaDB or Percona Server + Apache with HTTP/2 and event MPM + PHP-FPM 7 + Redis
  ([full feature list](/debian-setup.sh#L23))
- Every web application (or website) runs as a separate Linux user
- There are no passwords for Linux users, only SSH keys
- The server is accessible through SSH: **terminal, MySQL tunnel, file upload, code deploy** etc.
- TCP ports for web and SSH are heavily protected (maxretry=3) [with Fail2ban](/security/fail2ban-conf)
- PHP OPcache's [file timestamp validation](/webserver/phpfpm-pools/Skeleton-pool.conf#L30) is off,
  thus PHP files are read once at first access, we use [cachetool](https://github.com/gordalina/cachetool)
  to reset OPcache after a code change
- There are *standard* directories for [sessions, upload and tmp](/webserver/phpfpm-pools/Skeleton-pool.conf#L33-L35)
- `.htaccess` files are disabled, Apache rules should be in vhost configuration (it is faster)
- File versioning is not in query strings but turned into file names like `filename.002.ext` in URL-s,
  [an Apache rule](/webserver/apache-sites-available/Skeleton-site-ssl.conf#L151-L152) reverts them
- How to design and implement [CI and CD](/webserver/Continuous-integration-Continuous-delivery.md)
- [Running a Laravel application](/webserver/laravel)
- Interesting read on [web applications](/webserver/PHP-development.md)
