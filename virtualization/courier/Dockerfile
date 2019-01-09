#
# svarshavchik/courier
#
# VERSION       :0.1.0
# RELEASES      :https://www.courier-mta.org/download.html
# BUILD         :docker build -t svarshavchik/courier .
# BUILD         :docker build --build-arg COURIER_VERSION=1.0.5 -t svarshavchik/courier .

FROM fedora:latest

ARG COURIER_UNICODE_VERSION=2.1
ARG COURIER_AUTHLIB_VERSION=0.69.0
ARG COURIER_VERSION=1.0.5
ARG SF_BASEURL="https://sourceforge.net/projects/courier/files"

RUN set -e -x \
    && dnf -y update

RUN set -e -x \
    && dnf install -y which wget sudo rpm-build

RUN set -e -x \
    && dnf install -y expect mailcap gamin gamin-devel \
        gcc-c++ gdbm-devel ghostscript gnupg groff \
        libidn-devel mgetty-sendfax netpbm-progs \
        openssl-devel openssl-perl pam-devel pcre-devel \
        perl perl-generators procps-ng \
        libtool mysql-devel openldap-devel postgresql-devel \
        sqlite-devel libtool-ltdl-devel

RUN set -e -x \
    && adduser courier \
    && printf '\ncourier\tALL=(ALL)\tNOPASSWD: ALL\n' >>/etc/sudoers
USER courier
WORKDIR /home/courier/

RUN set -e -x \
    && wget --content-disposition "${SF_BASEURL}/courier-unicode/${COURIER_UNICODE_VERSION}/courier-unicode-${COURIER_UNICODE_VERSION}.tar.bz2/download" \
    && rpmbuild -ta courier-unicode-${COURIER_UNICODE_VERSION}.tar.bz2 \
    && ls ~/rpmbuild/RPMS/x86_64/courier-unicode-*.rpm | grep -vF -- '-debug' | xargs -L 1 -- sudo -- dnf install -y

RUN set -e -x \
    && wget --content-disposition "${SF_BASEURL}/authlib/${COURIER_AUTHLIB_VERSION}/courier-authlib-${COURIER_AUTHLIB_VERSION}.tar.bz2/download" \
    && rpmbuild -ta courier-authlib-${COURIER_AUTHLIB_VERSION}.tar.bz2 \
    && ls ~/rpmbuild/RPMS/x86_64/courier-authlib-*.rpm | grep -vF -- '-debug' | xargs -L 1 -- sudo -- dnf install -y

RUN set -e -x \
    && wget --content-disposition "${SF_BASEURL}/courier/${COURIER_VERSION}/courier-${COURIER_VERSION}.tar.bz2/download" \
    && rpmbuild -ta --define 'notice_option --with-notice=unicode' courier-${COURIER_VERSION}.tar.bz2 \
    && ls ~/rpmbuild/RPMS/x86_64/courier-[0-9]*.rpm | grep -vF -- '-debug' | xargs -L 1 -- sudo -- dnf install -y
