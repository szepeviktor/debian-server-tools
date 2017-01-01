#!/bin/bash

#docker rmi -f szepeviktor/jessie-build szepeviktor/jessie-backport

docker pull debian:jessie

docker build -t szepeviktor/jessie-build jessie-build
docker tag szepeviktor/jessie-build:latest \
    szepeviktor/jessie-build:$(sed -n -e 's|^# VERSION\s\+:\(\S\+\)$|\1|p' jessie-build/Dockerfile)

docker build -t szepeviktor/jessie-backport jessie-backport
docker tag szepeviktor/jessie-backport:latest \
    szepeviktor/jessie-backport:$(sed -n -e 's|^# VERSION\s\+:\(\S\+\)$|\1|p' jessie-backport/Dockerfile)

docker build -t szepeviktor/jessie-py2deb jessie-py2deb
docker tag szepeviktor/jessie-py2deb:latest \
    szepeviktor/jessie-py2deb:$(sed -n -e 's|^# VERSION\s\+:\(\S\+\)$|\1|p' jessie-py2deb/Dockerfile)
