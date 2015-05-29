# Uploading images to WordPress Media Library

### Set WordPress image sizes

Match display sizes in "Media Settings" `wp-admin/options-media.php`.

### Image format

- Convert photographic images to JPEG.
- Convert drawings to PNG.
- Save transparent images in PNG format.
- Avoid GIF and BMP.

### Image dimensions

- Minimum = smallest display size, [enlarge smaller images](https://github.com/szepeviktor/debian-server-tools/tree/master/image#enlarging).
- Maximum = largest display size.
- Display width in a lighbox: 1200 pixel or 1920 pixel.

### Image quality

Save images as JPEG 100% ("10" in Photoshop) then optimize images.

- [Windows Fast Image Optimizer](http://css-ig.net/fast-image-optimizer)
- [Windows PNG Gauntlet](http://pnggauntlet.com/)
- [Mac ImageOptim](https://imageoptim.com/)

##### Online tools

- [JPEGmini](http://www.jpegmini.com/)
- [Smush.it uploader](http://www.imgopt.com/)

### Extract images from Microsoft Office Word documents

- .doc: Save as a webpage ...
- .docx: Open with 7zip, or rename to document.zip, path: /word/media

### Image file name

Rename image file `categoryprefix-nice descriptive and SEO friendly may include spaces.jpg`.
Use dashes `-` or spaces ` ` as separator.
Avoid underscores `_`.
Rename `.jpeg` files to `.jpg`.
