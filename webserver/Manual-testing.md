# Manual Testing Handbook

Version 1.0.0

_Which code base do I test?_

`project-api`

_Which version do I test?_

Version `2.6.0` or commit hash

_On what device, browser am I testing?_

- **iPhone 6** operating system: iOS 13.2.2, browser: Mobile Safari v12.34
- **PC** Windows 10 v1803, Edge 42.17134.1038.0
- **PC** Debian GNU/Linux 10.1, Firefox 70.0.1
- Testing of AMP version

:bulb: Keep browser console open while testing, on mobile the _debug_ console.

### Testing the whole life-cycle

- Registration
- Approval or verification of successful payment/registration
- Testing of happy path for [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete),
  create (C), read (R), update (U) and delete (D) all entities
- Testing of unhappy path (e.g. 404 page, unsuccessful payment),
  checking helpful (not dead end) messages
- Testing already known and fixed errors
- Deletion of user account

### Testing compatibility

- Sharing (to be shared) pages on Twitter and Facebook
- Preview [Rich Results/Rich Snippets](https://search.google.com/test/rich-results)
  using "Structured Data"
- Does Google Tag Manager work?
- Checking pages work with an ad blocker (AdBlock)
- [more compatibility](Production-website.md#compatiblitity)

### Miscellaneous

- Testing non-web operations, e.g. Mailchimp email, mobile app, SMS sending
- Running test tools, e.g.
  https://securityheaders.io/ , https://validator.w3.org/ ,
  https://developers.google.com/speed/pagespeed/insights/
