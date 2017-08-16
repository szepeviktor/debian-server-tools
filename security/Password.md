# Password security

- https://github.com/dropbox/zxcvbn
- http://www.passwordmeter.com/
- https://ugyfelkapu.gov.hu/sugo/s-regisztracio/s-jelszokezelesi-szabalyzat

### Analysis

- Minimum lenght: 8
- Maximum length: 32
- Must contain characters: lowercase, uppercase, digit, symbol+space
- May not contain characters: ?
- Consecutive identical characters (aaa), alphabetical series (abc), number series (123), keyboard series (asd)
- Similarity to: username, previous password, email address, name

### Similarity

- soundex
- Levenshtein
- metaphone

http://php.net/manual/en/function.metaphone.php#39076

### Expiration

