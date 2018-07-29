#
# szepeviktor/stretch-build
#
# VERSION       :0.1.0
# BUILD         :docker build -t szepeviktor/stretch-build .
# RUN           :docker run --rm -i -t -v /opt/results:/opt/results szepeviktor/stretch-build

FROM debian:stretch

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y apt-utils \
    && apt-get install -y dirmngr sudo dialog wget nano devscripts git

RUN apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

RUN adduser --disabled-password --gecos "" debian
RUN printf 'debian\tALL=(ALL:ALL) NOPASSWD: ALL\n' >> /etc/sudoers

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]
