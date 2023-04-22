# Set up a domain for Google Workspace Gmail

Custom business email.

1. Register domain, see [Onboarding](/Onboarding.md)
1. Clean up DNS records
1. [Add domain](https://admin.google.com/ac/domains/manage)
1. Add TXT record `.`
    - `"google-site-verification=..."`
    - `"v=spf1 include:_spf.google.com -all"`
1. Add MX record `.`
    - `1 ASPMX.L.GOOGLE.COM.`
    - `5 ALT1.ASPMX.L.GOOGLE.COM.`
    - `5 ALT2.ASPMX.L.GOOGLE.COM.`
    - `10 ALT3.ASPMX.L.GOOGLE.COM.`
    - `10 ALT4.ASPMX.L.GOOGLE.COM.`

    After April 2023
    - `1 smtp.google.com.`
1. [Enable mailing](https://admin.google.com/ac/domains/manage)
1. [Generate DKIM record](https://admin.google.com/ac/apps/gmail/authenticateemail)
    1024 bit
1. Add generated TXT record `google._domainkey.`
1. Add report-only DMARC record `_dmarc.`
    - `"v=DMARC1; p=none; rua=mailto:postmaster@szepe.net"`
1. Use [Google Admin Toolbox](https://toolbox.googleapps.com/apps/checkmx/) Check MX service
    `https://toolbox.googleapps.com/apps/checkmx/check?dkim_selector=google&domain=EXAMPLE.COM`
1. Optional [SMTP relay](https://admin.google.com/ac/apps/gmail/routing)
