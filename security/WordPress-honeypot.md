# WordPress honeypot

https://sucuri.net/website-security/website-hacked-report#wordpress-analysis

- Most vulnerable (old) core version
- Most vulnerable plugins
- Most vulnerable themes (even inactive)
- Easy login: admin/(any password)
- Contact form
- nofollow links
- Disabled URL-s in robots.txt

Maybe multiple WordPress installations `/wordpress`, `/blog`

### Triggers and Protection

Check files: `git status`

Compare core options from `option-inspector/js/option-inspector.js`

`wp option list | grep -E "^(siteurl|home|blogname)\s"`

Check error log for contact form submit or successful login.

When triggered: LVM snapshot with database dump then restore files and database.
