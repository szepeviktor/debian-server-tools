# Hashcash

[Hashcash](https://en.wikipedia.org/wiki/Hashcash) is a proof-of-work system.

## Usage for browser validation

### Steps

- Bind to an event: lockIcon.onclick, window.onload, form.onsubmit
- Start visual feedback: animataion
- What to hash? nonce, counter, number of zeros, date, random string
- Hashing in a loop while `SHA256.startsWith == "00000"`
- Store result: input.value
- Stop visual feedback: animataion

### Hashing libs

- https://github.com/emn178/js-sha256
- https://github.com/digitalbazaar/forge/blob/master/webpack.config.js#L44

### Implementations

- https://github.com/barend-erasmus/hashcash-algorithm/blob/master/src/app.js
- https://gist.github.com/Xeoncross/d5a9482e5231db62fb87
