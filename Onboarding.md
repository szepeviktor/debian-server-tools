# Infrastructure and application setup for new clients

### Choose infrastructure providers

- Domain registrar (AWS, Gandi, noip, dyn, Rackforest/.hu)
- DNS provider (AWS, HE, Cloudflare, Rackforest/.hu)
- Server provider (UpCloud)
- SSL certificate provider for HTTPS (cheapsslsecurity.com, DigiCert)
- CDN provider (AWS)
- Transactional email provider (AWS, SparkPost)
- Storage provider (AWS)

### Infrastructure setup

- Document in hosting.yml / server.yml
- Gain access (web based sub-account or API)
- Manage migrations
- DNS records (check, clean up, monitor)
- PTR/IPv4 PTR/IPv6 records
- Incoming ESP and bounce notification
- My email address: `webmaster@COMPANY.TLD`
- Whitelisted IP-s (office)

### Application

- 3rd parties (document, gain access, set up)
- User names and SSH keys
- Git repository
- Issue tracker
- Paid plugins, libraries (update, access, support)
- Application environment
- Notifications (email, chat, SMS)
