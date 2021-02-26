# Set up origin pull CDN on Amazon CloudFront

### Static CDN settings

- Have CDN always serve files on HTTPS, redirect HTTP traffic to HTTPS, connect to origin through HTTPS
- Don't forward cookies
- Don't forward and base caching on query string

### Static origin settings

- [CloudFront does not support ECC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html#https-requirements-key-type)
  for origin connections
- Use `tiny-cdn` plugin for URL rewriting
- Set canonical HTTP header for CDN requests `Link: <https://example.com/path/image.jpg>; rel="canonical"`
- Don't let browsers send cookies to CDN on a subdomain
- Serve separate `robots.txt` for CDN
- Add `Host:` to both `robots.txt` files
- Add `Sitemap:` to both `robots.txt` files
- Log `X-Forwarded-For` in place of remote logname (`%l`) in `combined` log format

### Full-site CDN

- Create myattackers IP set: AWS WAF / IP sets / MyAttackers
- Create Web ACLs with rules
  - MyAttackers
  - AWS-AWSManagedRulesAmazonIpReputationList
  - AWS-AWSManagedRulesKnownBadInputsRuleSet
  - AWS-AWSManagedRulesPHPRuleSet
  - AWS-AWSManagedRulesSQLiRuleSet
  - request-rate-limit, e.g. 100 requests/5 minutes for API-s
- Allowed HTTP Methods: GET, HEAD for static routes
- Cache Behaviors
  - Cache Policy: Managed-CachingOptimized for static routes
  - Cache Policy: Managed-CachingDisabled for API-s and dynamic pages
  - Origin Request Policy
    - whitelist headers (`Accept`, `Accept-Language`, `Referer`, `User-Agent`, `X-XSRF-TOKEN`, `CloudFront-Viewer-Country`)
    - whitelist cookies
    - whitelist query strings
- Compress Objects Automatically: Yes
- Disable HTTP caching on the origin
  - `Expires: Thu, 01 Jan 1970 00:00:00 GMT`
  - `Cache-Control: no-store`
  - See https://aws.amazon.com/premiumsupport/knowledge-center/prevent-cloudfront-from-caching-files/
- Make origin fetch client IP address from `X-Forwarded-For` HTTP header

:bulb: [Limits](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html)

[Caching of HTTP 4xx and 5xx](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HTTPStatusCodes.html)

### Laravel TrustProxies

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Fideloper\Proxy\TrustProxies as Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Symfony\Component\HttpFoundation\HeaderBag;

class TrustProxies extends Middleware
{
    /**
     * The trusted proxies for this application.
     *
     * @var array|string|null
     */
    protected $proxies = '*';

    /**
     * The headers that should be used to detect proxies.
     *
     * @var int
     */
    protected $headers = Request::HEADER_X_FORWARDED_HOST | Request::HEADER_X_FORWARDED_FOR;

    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle(Request $request, Closure $next)
    {
        // Simulate host name to hide original host name behind CDN.
        $request->server->set('HTTP_X_FORWARDED_HOST', parse_url(Config::get('app.url'), PHP_URL_HOST));
        $request->headers = new HeaderBag($request->server->getHeaders());

        return parent::handle($request, $next);
    }
}
```

### Edge locations

- Budapest `130.176.34.64 - 130.176.34.95`
- Vienna `130.176.13.64 - 130.176.13.95`
