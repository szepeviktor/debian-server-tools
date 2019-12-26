#
# szepeviktor/jessie-backport
#
# VERSION       :0.2.4
# BUILD         :docker build --ulimit nofile=2048 -t szepeviktor/jessie-backport .
# RUN           :docker run --rm --tty --ulimit nofile=2048 -v $TARGET_PATH:/opt/results --env PACKAGE="$SOURCE-PACKAGE/$RELEASE" szepeviktor/jessie-backport

FROM szepeviktor/jessie-build

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

COPY debackport.sh /usr/local/bin/debackport.sh

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]

ENTRYPOINT ["/usr/local/bin/debackport.sh"]

# Run on Zeit Now
#ENV PACKAGE htop/testing
#EXPOSE 8080
#CMD /usr/local/bin/debackport.sh && cd /opt/results/ && python3 -m http.server 8080
