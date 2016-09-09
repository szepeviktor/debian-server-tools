# szepeviktor/jessie-build
#
# VERSION       0.2.3
# BUILD         docker build -t szepeviktor/jessie-build jessie-build
# RUN           docker run --rm -it -v /opt/results:/opt/results szepeviktor/jessie-build

FROM debian:jessie

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# httpredir.debian.org won't redirect to ftp.hu.debian.org
RUN sed -i -e 's|httpredir\.debian\.org|ftp.hu.debian.org|' /etc/apt/sources.list
RUN apt-get update && apt-get dist-upgrade -y --force-yes

RUN apt-get install -y sudo apt-utils dialog wget nano devscripts git
RUN apt-get clean

RUN adduser --disabled-password --gecos "" debian
RUN echo 'debian  ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]
