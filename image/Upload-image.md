# Uploading images to WordPress Media Library

### Set WordPress image sizes

Match display sizes in "Media Settings" `wp-admin/options-media.php`.

### Extract images

#### From Microsoft Office Word documents

- `.doc`: Save as a webpage ...
- `.docx`: Open with 7zip, or rename to document.zip, extract and see path: /word/media

#### From PDF files

http://www.somepdf.com/downloads.html

#### Erase or COPY text from images

http://projectnaptha.com/

### Online editors

- [Face retouch](http://makeup.pho.to/)
- [Editor.Pho.to](http://editor.pho.to/edit/)
- [Pixlr Editor](https://apps.pixlr.com/editor/)

### Image dimensions

- Minimum = smallest display size, [enlarge smaller images](https://github.com/szepeviktor/debian-server-tools/tree/master/image#enlarging).
- Maximum = largest display size.
- Display width in a full-screen lightbox: 1200 pixels or 1920 pixels.

### Image format

- Upload photographic images as JPEG-s.
- Upload drawings as PNG-s.
- Upload transparent images in PNG format.
- Avoid other formats (GIF, BMP).

### Image quality

Save images as 100% JPEG ("10" in Photoshop) then optimize images.

- [Windows Fast Image Optimizer](http://css-ig.net/fast-image-optimizer)
- [Windows PNG Gauntlet](http://pnggauntlet.com/)
- [Mac ImageOptim](https://imageoptim.com/)

##### Online optimization tools

- [SHORTPIXEL](https://shortpixel.com/free-demo)
- [JPEGmini](http://www.jpegmini.com/)
- [Smush.it uploader](http://www.imgopt.com/)

### Image file name

Rename image file `categoryprefix-nice descriptive and SEO friendly name may include spaces.jpg`.
Use dash `-` or space ` ` as separator.
Avoid underscore `_` character.
Use only `.jpg` and `.png` (lowercase) extensions.

### Image HTML attributes

After uploading set image `title` and `alt` attributes.

Title appears on mouse hover, alt(ernative text) is parsed by search engines.
