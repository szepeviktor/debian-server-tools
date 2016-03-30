# szepeviktor/jessie-py2deb
#
# VERSION 0.2.0
# BUILD docker build -t szepeviktor/jessie-py2deb jessie-py2deb
# RUN docker run --rm -v $TARGET_PATH:/opt/results --env PACKAGE="$PYTHON_PACKAGE" szepeviktor/jessie-py2deb

FROM szepeviktor/jessie-build

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sudo apt-get update
RUN sudo apt-get -y install fakeroot python-all python3-all python-stdeb python3-stdeb
RUN sudo apt-get clean

COPY docker-py2deb.sh /usr/local/bin/docker-py2deb.sh

VOLUME ["/opt/results"]
USER debian
WORKDIR /home/debian
ENTRYPOINT ["/usr/local/bin/docker-py2deb.sh"]
