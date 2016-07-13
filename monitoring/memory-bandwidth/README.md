# Bandwidth

A memory bandwidth benchmark. http://zsmith.co/bandwidth.html

```bash
# Download tar from https://mutineer.org/project.php?p=bandwidth
wget --content-disposition "https://mutineer.org/file.php?id=284ebee21bde256fd0daeae91242c2b73d9cf1df&p=bandwidth"
BW_VER=1.3.1
# Dependencies
apt-get install -y build-essential nasm
# Build
tar xf bandwidth-${BW_VER}.tar.gz
cd bandwidth-${BW_VER}/
make bandwidth64
# Run
nice -n -2 ./bandwidth64 --fast
```

It produces a BMP image.
