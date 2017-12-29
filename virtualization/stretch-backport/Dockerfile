#
# szepeviktor/stretch-backport
#
# VERSION       :0.1.0
# BUILD         :docker build -t szepeviktor/stretch-backport .
# RUN           :docker run --rm --tty -v $TARGET_PATH:/opt/results --env PACKAGE="$SOURCE-PACKAGE/$RELEASE" szepeviktor/stretch-backport

FROM szepeviktor/stretch-build

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

COPY debackport.sh /usr/local/bin/debackport.sh

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]

ENTRYPOINT ["/usr/local/bin/debackport.sh"]
