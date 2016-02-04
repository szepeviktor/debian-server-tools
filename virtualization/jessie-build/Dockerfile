# jessie-build
#
# VERSION 0.1.0

FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive
# httpredir.debian.org won't redirect to ftp.hu.debian.org
RUN sed -i -e 's/httpredir.debian.org/ftp.hu.debian.org/' /etc/apt/sources.list
RUN apt-get update && apt-get -y --force-yes dist-upgrade

RUN apt-get -y install dialog devscripts
RUN adduser --disabled-password --gecos "" debian

RUN apt-get clean
