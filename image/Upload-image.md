# Uploading images to WordPress Media Library

### Set WordPress image sizes

Match display sizes in "Media Settings" `wp-admin/options-media.php`.

### Image format

- Upload photographic images as JPEG-s.
- Upload drawings as PNG-s.
- Upload transparent images in PNG format.
- Avoid other formats (GIF, BMP).

### Image dimensions

- Minimum = smallest display size, [enlarge smaller images](https://github.com/szepeviktor/debian-server-tools/tree/master/image#enlarging).
- Maximum = largest display size.
- Display width in a full-screen lightbox: 1200 pixels or 1920 pixels.

### Image quality

Save images as JPEG 100% ("10" in Photoshop) then optimize images.

- [Windows Fast Image Optimizer](http://css-ig.net/fast-image-optimizer)
- [Windows PNG Gauntlet](http://pnggauntlet.com/)
- [Mac ImageOptim](https://imageoptim.com/)

##### Online tools

- [SHORTPIXEL](https://shortpixel.com/free-demo)
- [JPEGmini](http://www.jpegmini.com/)
- [Smush.it uploader](http://www.imgopt.com/)

### Extract images from Microsoft Office Word documents

- `.doc`: Save as a webpage ...
- `.docx`: Open with 7zip, or rename to document.zip, extract and see path: /word/media

### Image file name

Rename image file `categoryprefix-nice descriptive and SEO friendly name may include spaces.jpg`.
Use dash `-` or space ` ` as separator.
Avoid underscore `_` character.
Use only `.jpg` and `.png` (lowercase) extensions.
