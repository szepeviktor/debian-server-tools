#
# szepeviktor/jessie-py2deb
#
# VERSION       :0.2.1
# BUILD         :docker build -t szepeviktor/jessie-py2deb .
# RUN           :docker run --rm -v $TARGET_PATH:/opt/results --env PACKAGE="$PYTHON_PACKAGE" szepeviktor/jessie-py2deb

FROM szepeviktor/jessie-build

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN sudo apt-get update \
    && sudo apt-get -y install fakeroot python-all python3-all python-stdeb python3-stdeb

RUN sudo apt-get --purge -y autoremove \
    && sudo apt-get clean \
    && sudo find /var/lib/apt/lists -type f -delete

COPY docker-py2deb.sh /usr/local/bin/docker-py2deb.sh

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]

ENTRYPOINT ["/usr/local/bin/docker-py2deb.sh"]
