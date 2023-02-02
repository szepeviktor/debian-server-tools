# Features of a website

A checklist to test website functionality.

## Infrastructure

- DNS https://intodns.com/
- SSL certificate https://www.ssllabs.com/ssltest/
- CDN
- Cron jobs `wp cron event list`, `wp cron event run --due-now`
- Email delivery https://www.gmass.co/inbox https://www.mail-tester.com/

## Administration

- Administrators `/wp-admin/users.php?role=administrator`
- Yoast SEO `/wp-admin/admin.php?page=wpseo_dashboard`
- Comments

## Public parts

- Delete cookies!
- Check `HTTP/200` and `HTTP/404` response status codes
- Post content: front page, page types (see template files), header, footer
- Interactions: cookie consent, forms, registration, login, password reset, social login, share, search
- `/favicon.ico`
- `/apple-touch-icon.png`
- `/robots.txt`
- `/sitemap_index.xml`

### Per URL checks

- Supported devices, operating systems, browsers
- Errors on browser console
- HTML headers https://redbot.org/ https://securityheaders.com/
- HTML output https://validator.w3.org/
- https://www.webpagetest.org/
- RSS feed https://validator.w3.org/feed/
- Ad blockers

## Other service providers

Keep an up-to-date list of these providers.

- Font: see rendered fonts
- Video: play a video
- Map: load map
- HTML widgets
- Advertisement: check event submission
- Visitor tracking: see statistics
- Payment gateway: pay
- Authentication: log in
- Error tracking: see reports

## Web services

- Google Search Console / Page indexing
- SERP: search for `site:example.com`
- How content shared on social media looks like
- Website translation services
