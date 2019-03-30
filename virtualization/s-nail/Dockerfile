#
# szepeviktor/s-nail
#
# DOCS          :https://www.sdaoden.eu/code.html#s-mailx
# BUILD         :docker build -t szepeviktor/s-nail .
# RUN           :docker run --tty --rm szepeviktor/s-nail

FROM debian:stretch

# Dependencies from https://salsa.debian.org/debian/s-nail/blob/master/debian/control
RUN set -e -x \
    && apt-get update \
    && apt-get install -y git build-essential \
        openssl libidn11-dev libkrb5-dev libncurses5-dev libssl-dev

RUN set -e -x \
    && apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

# Build
CMD set -e -x \
    && git clone --branch master "https://git.sdaoden.eu/scm/s-nail.git" s-nail \
    && cd s-nail/ \
    && make CONFIG=MAXIMAL all \
    && echo "OK."
