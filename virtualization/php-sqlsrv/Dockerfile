#
# Build Microsoft Drivers for PHP for SQL Server as a Debian package.
#
# VERSION       :5.2.0
# DOCS          :https://docs.microsoft.com/en-us/sql/connect/php/system-requirements-for-the-php-sql-driver?view=sql-server-2017
# BUILD         :docker build -t szepeviktor/php7.2-sqlsrv:5.2.0 .
# RUN           :docker run --rm --tty -v /mnt:/mnt szepeviktor/php7.2-sqlsrv:5.2.0

FROM debian:stretch

ARG php_version="7.2"
ARG msodbcsql_version="17.1.0.1-1"

LABEL maintainer="viktor@szepe.net"

ENV LC_ALL="C"
ENV DEBIAN_FRONTEND="noninteractive"

# OS
RUN set -e -x \
    && apt-get update \
    && apt-get install -y apt-utils \
    && apt-get install -y dialog sudo wget nano apt-transport-https devscripts git \
    && wget -qO- https://packages.sury.org/php/apt.gpg | apt-key add - \
    && echo "deb https://packages.sury.org/php/ stretch main" > /etc/apt/sources.list.d/sury-php.list \
    && apt-get update \
    && apt-get upgrade -y

# OS packages
RUN set -e -x \
    && apt-get install -y po-debconf docbook-xsl xsltproc php-pear cdbs \
    libcurl3 unixodbc unixodbc-dev php${php_version}-cli php-cli php${php_version}-dev php-dev

# Clean package cache
RUN set -e -x \
    && apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

# User account
RUN set -e -x \
    && adduser --disabled-password --gecos "" php \
    && printf 'php\tALL=(ALL:ALL) NOPASSWD: ALL\n' >> /etc/sudoers
USER php
WORKDIR /home/php

# Install dh-make-php from master branch
RUN set -e -x \
    && git clone https://github.com/Avature/dh-make-php.git \
    && cd dh-make-php/ \
    && dpkg-buildpackage -uc -us \
    && cd - \
    && sudo -- dpkg -i dh-make-php_*_all.deb

# Microsoft ODBC Driver for SQL Server
# https://packages.microsoft.com/debian/stretch/prod/pool/main/m/msodbcsql17/
RUN set -e -x \
    && wget "https://packages.microsoft.com/debian/stretch/prod/pool/main/m/msodbcsql17/msodbcsql17_${msodbcsql_version}_amd64.deb" \
    && sudo ACCEPT_EULA=Y -- dpkg -i msodbcsql17_${msodbcsql_version}_amd64.deb

# Build php-sqlsrv from PECL stable
CMD set -e -x \
    && sudo -- pecl channel-update pecl.php.net \
    && sudo -- pecl update-channels \
    && sudo -- pecl download pdo_sqlsrv \
    && dh-make-pecl --package-name "sqlsrv" \
    --maintainer "Viktor Szepe <viktor@szepe.net>" \
    --depends "php-common (>= 1:61), phpapi-$(/usr/bin/php-config --phpapi)" \
    pdo_sqlsrv-*.tgz \
    && cd php-sqlsrv-*/ \
    && sed -e 's|^PECL_PKG_NAME=sqlsrv|PECL_PKG_NAME=pdo_sqlsrv|' -i debian/rules \
    && mv debian/sqlsrv.ini debian/pdo_sqlsrv.ini \
    && sed -e 's|^extension=sqlsrv\.so|extension=pdo_sqlsrv.so|' -i debian/pdo_sqlsrv.ini \
    && dpkg-buildpackage -uc -us \
    && cd - \
    && sudo -- mv -v php-sqlsrv_*_amd64.deb /mnt/
