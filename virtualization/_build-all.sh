#!/bin/bash

#docker rmi -f szepeviktor/stretch-build szepeviktor/stretch-backport

docker pull debian:stretch

docker build -t szepeviktor/stretch-build stretch-build
docker tag szepeviktor/stretch-build:latest \
    "szepeviktor/stretch-build:$(sed -n -e 's/^# VERSION\s\+:\(\S\+\)$/\1/p' stretch-build/Dockerfile)"

docker build -t szepeviktor/stretch-backport stretch-backport
docker tag szepeviktor/stretch-backport:latest \
    "szepeviktor/stretch-backport:$(sed -n -e 's/^# VERSION\s\+:\(\S\+\)$/\1/p' stretch-backport/Dockerfile)"

docker build -t szepeviktor/stretch-py2deb stretch-py2deb
docker tag szepeviktor/stretch-py2deb:latest \
    "szepeviktor/stretch-py2deb:$(sed -n -e 's/^# VERSION\s\+:\(\S\+\)$/\1/p' stretch-py2deb/Dockerfile)"
