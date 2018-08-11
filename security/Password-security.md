# Password security

- https://github.com/dropbox/zxcvbn
- http://www.passwordmeter.com/
- https://ugyfelkapu.gov.hu/sugo/s-regisztracio/s-jelszokezelesi-szabalyzat (HU)

### Complexity

- Minimum lenght: 8
- Maximum length: 32
- Must contain characters: lowercase, uppercase, digit, symbol+space
- May not contain characters: ?
- Consecutive identical characters (aaa), alphabetical series (abc), number series (123), keyboard series (asd)
- Similarity to username, previous password, email address, name
- Don't allow TOP 1000 passwords,
  [TOP 100 (HU)](https://blog.crysys.hu/2013/11/hungarian-passwords-in-the-adobe-leaked-password-list/)

### Similarity

- soundex
- Levenshtein
- [metaphone](https://secure.php.net/manual/en/function.metaphone.php#39076)
- https://siderite.blogspot.com/2014/11/super-fast-and-accurate-string-distance.html

### Expiration
