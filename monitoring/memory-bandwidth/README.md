# Bandwidth

A memory bandwidth benchmark. http://zsmith.co/bandwidth.html

```bash
#BW_VER=1.4 "Sequential read (256-bit), size = 256 B, Illegal instruction"
BW_VER=1.3.1
##wget --content-disposition "http://zsmith.co/archives/bandwidth-${BW_VER}.zip"
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
