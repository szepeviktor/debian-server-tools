# Docker

https://docs.docker.com/engine/reference/builder/

### Debian images

1. [debian:jessie](https://github.com/tianon/docker-brew-debian) 125MB
1. [monsantoco/min-jessie](https://github.com/MonsantoCo/docker-min-jessie) 82MB
1. [accursoft/micro-jessie](https://bitbucket.org/accursoft/micro-debian) 38MB
1. [alpine](http://gliderlabs.viewdocs.io/docker-alpine/) 5 MB

### Package builder environment with Docker

```bash
# - Build "szepeviktor/jessie-build" image -
# docker build -t szepeviktor/jessie-build jessie-build


# - Build Debian package -
# docker run --rm -it -v /opt/result --user=1000 szepeviktor/jessie-build


# @TODO Automate in a Dockerfile !!! ENV PACKAGE=htop


read -r -p "Package? " P
R="testing"; WEB="https://packages.debian.org/${R}/${P}"
URL="$(curl -s "$WEB"|grep -o 'http://http.debian.net/debian/pool/[^"]\+\.dsc')"
[ -z "$URL" ] || dget -ux "$URL"
cd ${P}-*/
dpkg-checkbuilddeps 2>&1 | cut -d: -f3- | sed 's/([^()]\+)//g'

# docker exec $(docker ps -q|head -n1) /bin/bash -c "apt-get install -y DEPENDENCIES"

dpkg-buildpackage -b -uc -us || echo ERROR
cd ../
lintian *.deb && ls -l *.deb && logout

# docker exec $(docker ps -q|head -n1) /bin/bash -c "cd /home/debian/;tar c *.deb"|tar xv
# cp -av "$(docker inspect $(docker ps -q|head -n1)|grep -A10 '"Mounts":'|grep -m1 '"Source": ".*",'|cut -d'"' -f4)" .
```
