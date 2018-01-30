# Vim for PHP only

- Download vim: `apt-get download vim vim-runtime`
- Extract `usr/bin/vim.basic` as `~/bin/`
- Extract syntax files from `usr/share/vim/vim80/syntax/` to `~/.vim/syntax/`
  - css.vim
  - html.vim
  - javascript.vim
  - php.vim
  - sql.vim
  - sqloracle.vim
  - syncolor.vim
  - synload.vim
  - syntax.vim
  - vb.vim
- Extract additional files from `usr/share/vim/vim80/` to `~/.vim/`
  - debian.vim
  - defaults.vim
  - filetype.vim
  - rgb.txt
- Create shell script `~/bin/vim` with content `VIMRUNTIME=~/.vim exec ~/bin/vim.basic "$@"`

```bash
mkdir -p ~/.vim/syntax
for F in css html javascript php sql sqloracle syncolor synload syntax vb;
do cp -v syntax/${F}.vim ~/.vim/syntax/; done
for F in defaults.vim filetype.vim rgb.txt;
do cp -v ./$F ~/.vim/; done
echo 'VIMRUNTIME=~/.vim exec ~/bin/vim.basic "$@"' > ~/bin/vim; chmod +x ~/bin/vim
```
