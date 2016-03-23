# jessie-py2deb
#
# VERSION 0.1.0
# BUILD docker build -t szepeviktor/jessie-py2deb jessie-py2deb

FROM debian:jessie

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
RUN sed -i -e 's/httpredir.debian.org/ftp.hu.debian.org/' /etc/apt/sources.list
RUN apt-get update && apt-get -y --force-yes dist-upgrade

RUN apt-get -y install dialog devscripts \
    fakeroot python-all python3-all python-stdeb python3-stdeb
RUN adduser --disabled-password --gecos "" debian

RUN apt-get clean

COPY docker-py2deb.sh /usr/local/bin/docker-py2deb.sh

# docker run --rm --user=1000 --workdir=/home/debian --entrypoint=/usr/local/bin/docker-py2deb.sh
