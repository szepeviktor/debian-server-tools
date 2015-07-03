# Secure Contact Form

// config: (printf templates) from/name, to/name, headers, subject, text
// config: error messages: empty fields, invalid fields, Sent, send failure
// charset = UTF-8
// phpmailer https://github.com/Synchro/PHPMailer/archive/master.zip
// inline js, css


//TWO parts: nonce generator; form action; nonce_gen HTTP req. on form.focus()
//let it be a class

### Security

\n|\r=breach, $mb_char < ASCII(32)=breach
not all fields (more, less)=breach
nonce in $_SESSION, incorrect nonce=breach, $nonce = uniqid(mt_rand(), true);, input type=hidden
only POST, other action=breach
breach HTTP/500

### Anti-spam

hidden field, filled=spam
config: must have UA "^Mozilla/"
js=must, js to inject nonce, no-js warning
spam HTTP/500
min time to fill

### Validation

trim fields
input type=email: format, MX check: typo regexp-s + corrections
address typos (from list)
required fields (not empty)
on invalid refill fields

// ----

config:plain or plain+HTML mail
invalid UTF8 strings=breach
input type:URL
input type:number
input type:file
MX check NS fail?
log HTTP request (POST) data.serialize() to prefix_microtime(true)_rand().log
config:log prefix

preg_replace("/ +/", ' ', trim($string));
preg_replace("/[<>]/", '_', $string);
// Clean up the input values
foreach($_POST as $key => $value) {
  if (ini_get('magic_quotes_gpc')) $_POST[$key] = stripslashes($_POST[$key]);
  $_POST[$key] = htmlspecialchars(strip_tags($_POST[$key]));
}
str_replace('&', '&amp;', $string);
str_replace('"', '&quot;', $string);
str_replace("'", '&#39;', $string);
str_replace('<', '&lt;', $string);
str_replace('>', '&gt;', $string);
"/(<CR>|<LF>|\r|\n|%0a|%0d|content-type|mime-version|content-transfer-encoding|to:|bcc:|cc:|document.cookie|document.write|onmouse|onkey|onclick|onload)/i"
must have HTTP/UA and HTTP/Accept and HTTP/Referer, blank=breach
config:must have a defined referer, not=breach
config:filed min/max length, for validation+input size
input type:password
too fast POST=breach, time into $_SESSION, config: min_fill_time
?DDoS (GET/POST)
IP ban list=regexp
UA ban list=regexp
config:sender in from/sender in reply-to
?DNSBL,httpbl,Akismet -> bad-behavior
? red herring form (display:none) sent=breach
? must use HTTP/1.1
? no (Session) cookie=breach
config:own host referer/not
?ban list in htaccess/sql (atomic writes)
config:HTTP/response code 500/403....
config:redirect address/redirect to referer
config:IP whitelist, UA whitelist
config:debug log
input fields:additional fields=names only (e.g. selects)

config: email notify on breach
    Time stamp: Dec. 28th, 2007 &#64; 10:45 pm
    Whois: http://ws.arin.net/cgi-bin/whois.pl?queryinput=00.00.00.00 (IP:proxy, Opera Turbo, CloudFlare)
    PTR: c-00.00.00.00.hsd1.xx.comcast.net
    UA: Firefox on Windows
    Ref: http://green-beast.com/gbcf-v3/test-form.php
    HTTP req.serialize()

