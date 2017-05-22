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
#    regex/\.md(own)?$
#    	View=pandoc -s -f markdown -t man %p | man -l -
```
