# Set up origin pull CDN on Amazon CloudFront

### CDN settings

- [CloudFront does not support ECC](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html) for origin connections
- Have CDN always serve files on HTTPS, and redirect HTTP traffic to HTTPS
- Don't forward cookies
- Don't forward and base caching on query string

### Origin settings

- URL rewriting - `tiny-cdn` plugin
- Set canonical HTTP header for CDN requests - `Link: <https://example.com/path/image.jpg>; rel="canonical"`
- Serve separate `robots.txt` for CDN
- Log `X-Forwarded-For` - in place of referer in `combined` log format
- Don't let browsers send cookies to CDN on a subdomain
- Add `Host:` to both `robots.txt`-s
