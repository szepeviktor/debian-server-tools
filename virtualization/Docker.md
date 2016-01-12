# Docker

### Debian images

debian:jessie 125MB - https://github.com/tianon/docker-brew-debian
monsantoco/min-jessie 82MB - https://github.com/MonsantoCo/docker-min-jessie
accursoft/micro-jessie 38MB - https://bitbucket.org/accursoft/micro-debian
alpine 5 MB - http://gliderlabs.viewdocs.io/docker-alpine/

### Package builder environment with Docker

```bash
# docker run -it --entrypoint=/bin/bash debian:jessie
#apt-get update
#apt-get install -y dialog devscripts
#adduser --disabled-password --gecos "" debian
# docker commit $(docker ps -q|head -n1) szepeviktor/jessie-build

# docker run --rm -it --entrypoint=/bin/bash szepeviktor/jessie-build

su -l debian
read -r -p "Package? " P
R="testing"; WEB="https://packages.debian.org/${R}/${P}"
URL="$(curl -s "$WEB"|grep -o 'http://http.debian.net/debian/pool/[^"]\+\.dsc')"
[ -z "$URL" ] || dget -ux "$URL"
cd $P-*/
dpkg-checkbuilddeps 2>&1|cut -d: -f3-|sed 's/([^()]\+)//g'

# docker exec $(docker ps -q|head -n1) /bin/bash -c "apt-get install -y DEPENDENCIES"

dpkg-buildpackage -b -uc -us || echo ERROR
cd ../
lintian *.deb && ls -l *.deb && logout

# docker exec $(docker ps -q|head -n1) /bin/bash -c "cd /home/debian/;tar c *.deb"|tar xv
```
