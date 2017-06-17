# Bandwidth

A memory bandwidth benchmark. http://zsmith.co/bandwidth.html

```bash
BW_VER=1.4.2
# Dependencies
apt-get install -y build-essential nasm
wget --content-disposition "http://zsmith.co/archives/bandwidth-${BW_VER}.tar.gz"
tar -xf "bandwidth-${BW_VER}.tar.gz"
cd bandwidth-${BW_VER}/
make bandwidth64
# Use fastest mode to aviod averages
nice -n -2 ./bandwidth64 --fastest
```

It produces a BMP image.
