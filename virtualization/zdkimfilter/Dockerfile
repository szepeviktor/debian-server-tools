#
# szepeviktor/zdkimfilter
#
# BUILD         :docker build -t szepeviktor/zdkimfilter:2.1 .
# RUN           :docker run --rm --tty -v /mnt:/mnt szepeviktor/zdkimfilter:2.1

FROM debian:stretch

ARG VERSION=2.1

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN set -e -x \
    && apt-get update \
    && apt-get install -y wget subversion unzip build-essential courier-mta \
                          libtool-bin m4 gettext autoconf pkg-config publicsuffix \
                          libopendkim-dev uuid-dev zlib1g-dev libunistring-dev nettle-dev libopendbx1-dev \
    && echo "Getting https://packages.debian.org/source/stretch-backports/libidn2 ..." \
    && wget "http://ftp.de.debian.org/debian/pool/main/libi/libidn2/libidn2-0_2.0.5-1~bpo9+1_amd64.deb" \
    && wget "http://ftp.de.debian.org/debian/pool/main/libi/libidn2/libidn2-dev_2.0.5-1~bpo9+1_amd64.deb" \
    && dpkg -i libidn2-*_amd64.deb

RUN set -e -x \
    && mkdir /usr/local/src/zdkimfilter

WORKDIR /usr/local/src/zdkimfilter

RUN set -e -x \
    && svn checkout "http://www.tana.it/svn/zdkimfilter/tags/v${VERSION}/" . \
    && unzip m4_redist.zip \
    && libtoolize \
    && aclocal \
    && autoheader --verbose \
    && touch NEWS README AUTHORS ChangeLog \
    && automake --verbose --add-missing \
    && autoreconf --verbose --symlink --install

RUN set -e -x \
    && ./configure --prefix=/usr --enable-zdkimsign-setuid \
    && make

RUN set -e -x \
    && make check \
    && file src/zdkimfilter \
    && ldd src/zdkimfilter \
    && src/zdkimfilter --version

CMD set -e -x \
    && apt-get install -y debhelper lintian \
    && sed -i -e 's#export DEB_BUILD_HARDENING=1#export DEB_BUILD_MAINT_OPTIONS=hardening=+all#' debian/rules \
    && dpkg-buildpackage -uc -us -B \
    && lintian --display-info --display-experimental --pedantic --show-overrides ../zdkimfilter*.deb \
    && cp -v -f ../zdkimfilter*.deb /mnt/
