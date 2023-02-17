# Norton Safe Web

Register a website and recieve notification of site rating changes.

1. Navigate to https://safeweb.norton.com/saml/login
1. Click on "Create an account"
1. Create an Account and verify your email
1. Your name (top right corner) / "My Profile"
    / ["Site Management" tab](https://safeweb.norton.com/site_dispute)
1. Click "Add site" button and enter URL
1. Click on "Verify your site" 
1. Open "Upload an HTML file" and follow all four steps
1. Click on "Notify me when site rating changes"
1. If displayes click on "Rate my site"
1. Your name (top right corner) / "My Profile" / "Signout"

## Safe Web Report

- Web version: https://safeweb.norton.com/report/show?url=https://example.com/
- XML version: https://ratings-wrs.norton.com/brief?url=https://example.com/

## Safe Web XML API

Sample response

```xml
<?xml version="1.0"?>
<symantec v="2.5" cacheP="600" cacheN="600">
	<site id="example.com" r="g" sr="g" br="u" cache="600">
	</site>
</symantec>
```

Response fields meanings

- `site.id` means CANONICAL_SITE_ID_ATTR
- `site.r` means COMBINED_RATING_ATTR
- `site.sr` means SECURITY_RATING_ATTR
- `site.br` means BUSINESS_RATING_ATTR, also called _shopping rating_

Ratings values meanings

- `u` means UNKNOWN_SITE (gray color)
- `b` means BAD_SITE (red color)
- `w` means WARNING_SITE (orange color)
- `g` means GOOD_SITE (green color)
- `r` means NORTON_SECURE_SITE (sites having Norton Seal)
- `n` means PII_NOT_ENABLED (personally identifiable information)
- `y` means PII_ENABLED (personally identifiable information)
- `s` means PII_SILENCE (personally identifiable information)
- `grbl` means REGIONAL_BLOCK

Source: https://addons.mozilla.org/en-US/firefox/addon/norton-safe-web/
