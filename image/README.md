# BGP image format

- http://xooyoozoo.github.io/yolo-octo-bugfixes/#camel&bpg=s&jpg=s
- https://github.com/mirrorer/libbpg/tree/master/html

# JPEG manipulations

### Lossy minification

- https://github.com/danielgtaylor/jpeg-archive (mozjpeg)
- https://github.com/rflynn/imgmin

### Lossless compression

- see: image/jpegrescan
- http://packjpg.encode.ru/?page_id=17

### JPEG artifacts removal

- http://www.vicman.net/jpegenhancer/ http://mirror.szepe.net/software/jpeginst.exe
- http://enhance.pho.to/
- http://www.topazlabs.com/dejpeg
- Photoshop / Ps Elements: Filter > Noise > Reduce Noise  [x] Remove JPEG Artifacts

### Enlarging

- http://www.alienskin.com/blowup/
- http://vectormagic.com/online/how_it_works
- [Inkscape Trace bitmap](https://inkscape.org/doc/tracing/tutorial-tracing.html)

### Scaling

- [GIMP Liquid rescale](http://liquidrescale.wikidot.com/)
- [Photoshop Content-Aware Scale](https://helpx.adobe.com/photoshop/using/content-aware-scaling.html)

### Super-Resolution demo

- [Super-Resolution From a Single Image](http://www.wisdom.weizmann.ac.il/~vision/SingleImageSR.html)

### Face retouch

http://makeup.pho.to/

### Edit

- http://editor.pho.to/edit/
- http://apps.pixlr.com/editor/

### Archiving

- packJPG (already in pcompress)

### Invalited objects on Amazon CloudFront

```bash
alias encodeURIComponent='perl -pe '\''s/([^a-zA-Z0-9_.!~*()'\''\'\'''\''-])/sprintf("%%%02X",ord($1))/ge'\'
cat URL_LIST|while read URL;do echo -n "$URL"|encodeURIComponent;echo;done|sed 's/%2F/\//g'
```