# Bandwidth

A memory bandwidth benchmark. http://zsmith.co/bandwidth.html

```bash
# Download tar from https://mutineer.org/project.php?p=bandwidth
BW_VER=1.3.1
BW_ID=284ebee21bde256fd0daeae91242c2b73d9cf1df
##wget --content-disposition "https://mutineer.org/file.php?id=${BW_ID}&p=bandwidth"
# Dependencies
apt-get install -y build-essential nasm
# https://github.com/szepeviktor/bandwidth
wget -qO- "https://github.com/szepeviktor/bandwidth/archive/v${BW_VER}.tar.gz" | tar xz
cd bandwidth-${BW_VER}/
make bandwidth64
# Use fastest mode to aviod averages
nice -n -2 ./bandwidth64 --fastest
```

It produces a BMP image.
