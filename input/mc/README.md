```bash
install --mode=0644 ./install email.syntax ~/.local/share/mc/mcedit/
install --mode=0644 ./install markdown.syntax ~/.local/share/mc/mcedit/
install --mode=0644 ./Syntax ~/.config/mc/mcedit/
cat /usr/share/mc/syntax/Syntax >> ~/.config/mc/mcedit/Syntax

install --mode=0644 ./menu ~/.config/mc/mcedit/
```

User menu file: `~/.config/mc/mcedit/menu`

Per directory menu file: `.cedit.menu`

### Markdown viewer

```bash
apt-get install -y pandoc
cp -v /etc/mc/mc.ext ~/.config/mc/mc.ext
editor ~/.config/mc/mc.ext
#    regex/\.m(ark)?d(own)?$
#    	View=pandoc -s -f markdown -t man %p | man -l -
```

### Image viewer

`~/.mailcap`

```mailcap
# /usr/lib/mc/ext.d/image.sh -> xdg-open -> run-mailcap -> Processing file "-" of type "text/plain"
text/plain;             less -R;
image/jpeg;             jp2a --term-fit --background=dark --color %s; copiousoutput;
image/pjpeg;            jp2a --term-fit --background=dark --color %s; copiousoutput;
image/png;              convert %s -flatten -quality 100 jpeg:- | jp2a --term-fit --background=dark --color -; copiousoutput;
image/gif;              convert %s -flatten -quality 100 jpeg:- | jp2a --term-fit --background=dark --color -; copiousoutput;
image/x-photoshop;      convert %s -flatten -quality 100 jpeg:- | jp2a --term-fit --background=dark --color -; copiousoutput;
```

```bash
apt-get install -y imagemagick exif libimage-exiftool-perl jp2a

cp /usr/lib/mc/ext.d/image.sh /usr/local/bin/mc-extd-image.sh
sed -i -e '/MC_XDG_OPEN/s| 2>/dev/null||' /usr/local/bin/mc-extd-image.sh

# cp /etc/mc/mc.ext ~/.config/mc/
editor ~/.config/mc/mc.ext
#    shell/i/.psd
#    	View=%view{ascii} exiftool %p
#    	Include=image
#    include/image
#    	Open=/usr/local/bin/mc-extd-image.sh open ALL_FORMATS %var{LESS:R}
#    	View=%view{ascii} /usr/lib/mc/ext.d/image.sh view ALL_FORMATS
```

### Photoshop Thumbnail viewer

```bash
apt-get install -y libimage-exiftool-perl
exiftool -Photoshop:PhotoshopThumbnail -b -w jpg DESIGN.psd
```
