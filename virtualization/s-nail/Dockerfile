#
# szepeviktor/s-nail
#
# BUILD         :docker build -t szepeviktor/s-nail .
# RUN           :docker run --tty --rm szepeviktor/s-nail

FROM debian:stretch

# Dependencies
RUN set -e -x \
    && apt-get update \
    && apt-get install -y git build-essential original-awk \
    && apt-get purge mawk -y

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
