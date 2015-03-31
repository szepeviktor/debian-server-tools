# JPEG manipulations

### Lossy minification

- https://github.com/rflynn/imgmin

### Lossless compression

- http://packjpg.encode.ru/?page_id=17

### JPEG artifacts removal

- http://www.vicman.net/jpegenhancer/
- http://www.topazlabs.com/dejpeg
- Photoshop / Ps Elements: Filter > Noise > Reduce Noise  [x] Remove JPEG Artifacts

### Enlarging

- http://www.alienskin.com/blowup/
- http://vectormagic.com/online/how_it_works
- [Inkscape Trace bitmap](https://inkscape.org/doc/tracing/tutorial-tracing.html)

### Scaling

- [GIMP Liquid rescale](http://liquidrescale.wikidot.com/)

### Super-Resolution demo

- [Super-Resolution From a Single Image](http://www.wisdom.weizmann.ac.il/~vision/SingleImageSR.html)

### Archiving

- packJPG (already in pcompress)

### Invalited objects on Amazon CloudFront

```bash
alias encodeURIComponent='perl -pe '\''s/([^a-zA-Z0-9_.!~*()'\''\'\'''\''-])/sprintf("%%%02X",ord($1))/ge'\'
cat URL_LIST|while read URL;do echo -n "$URL"|encodeURIComponent;echo;done|sed 's/%2F/\//g'
```