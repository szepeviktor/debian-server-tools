# Infrastructure and application setup for new clients

*Welcome to the process of setting up your infrastructure and your application!*

Details about [infrastructure and source code management](/master/CV.md)

### Choose infrastructure providers

- Domain registrar (AWS, Gandi, noip, dyn, Rackforest/.hu)
- DNS provider (AWS, HE, Cloudflare, [Google](https://cloud.google.com/dns/pricing), Rackforest/.hu)
- Server provider (UpCloud)
- SSL certificate provider for HTTPS (cheapsslsecurity.com, [SSLMate](https://sslmate.com/), DigiCert)
- CDN provider (AWS, KeyCDN)
- Transactional email provider (AWS, SparkPost)
- Storage provider (AWS, Backblaze B2, Exoscale, Selectel)

[.hu domain regisztrátorok](http://www.domain.hu/domain/)

[Google Cloud Platform Premium Support for $150/mo](https://cloud.google.com/support/?options=premium-support#options)

[AWS certificates for internal usage only](https://aws.amazon.com/certificate-manager/faqs/#services_used)

### Infrastructure setup

- Document in hosting.yml / server.yml
- Gain access to providers (web based sub-account or API)
- Manage migrations
- DNS records (check, clean up, monitor)
- PTR/IPv4, PTR/IPv6 records
- Incoming ESP and bounce notification
- My email address: `webmaster@COMPANY.TLD`
- Whitelisted IP-s (office)

### Application

- 3rd parties (document, gain access, set up)
- User names and SSH keys
- Git repository, branch usage (git flow)
- Issue tracker
- Paid plugins, libraries (updates, gain access, support)
- Application environment definition
- Set up CI
- Write deploy script
- Notifications (email, chat, SMS)
