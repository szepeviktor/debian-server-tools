#
# szepeviktor/jessie-build
#
# VERSION       :0.2.5
# BUILD         :docker build -t szepeviktor/jessie-build .
# RUN           :docker run --rm -it -v /opt/results:/opt/results szepeviktor/jessie-build

FROM debian:jessie

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sed -i -e 's|deb\.debian\.org|debian-archive.trafficmanager.net|' /etc/apt/sources.list
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
    && apt-get install -y sudo dialog wget nano devscripts git

RUN apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

RUN adduser --disabled-password --gecos "" debian
RUN echo 'debian  ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]
