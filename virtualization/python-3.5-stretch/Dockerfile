#
# szepeviktor/python
#
# DOCS          :https://github.com/docker-library/python/blob/master/3.5/stretch/Dockerfile
# BUILD         :docker build -t szepeviktor/python:3.5.7-stretch .

FROM python:3.5-stretch

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN set -e -x \
    && apt-get update \
    && apt-get install -y gpg dirmngr

RUN set -e -x \
    && apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete
