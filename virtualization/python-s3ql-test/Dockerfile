#
# szepeviktor/python-s3ql-test
#
# BUILD         :docker build -t szepeviktor/python-s3ql-test:stretch-0.3.0 .
# RUN           :docker run --tty --rm --cap-add SYS_ADMIN --device /dev/fuse szepeviktor/python-s3ql-test:stretch-0.3.0

FROM python:3.6-stretch

# Dependencies
RUN set -e -x \
    && /bin/echo "deb http://deb.debian.org/debian bullseye main" >/etc/apt/sources.list.d/bullseye.list \
    && /bin/echo -e "Package: *\nPin: release o=Debian,a=testing,n=bullseye\nPin-Priority: 80" >/etc/apt/preferences.d/bullseye-fuse3 \
    && /bin/echo -e "\nPackage: fuse3* libfuse3*\nPin: release o=Debian,a=testing,n=bullseye\nPin-Priority: 990" >>/etc/apt/preferences.d/bullseye-fuse3 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        psmisc pkg-config libattr1-dev libsqlite3-dev libjs-sphinxdoc mercurial \
        texlive-latex-base texlive-latex-recommended texlive-latex-extra \
        texlive-generic-extra texlive-fonts-recommended \
    && apt-get install -y -t bullseye libfuse3-dev fuse3 \
    && apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

# apsw must be the same version as libsqlite3 in Debian
# https://packages.debian.org/stretch/libsqlite3-dev
#     dpkg-query --show --showformat='${Version}' libsqlite3-dev | sed -e 's#-.*$#-r1#'
# apsw==3.16.2-r1 in stretch
RUN set -e -x \
    && pip --no-cache-dir install -U "https://github.com/rogerbinns/apsw/releases/download/3.16.2-r1/apsw-3.16.2-r1.zip"

# http://www.rath.org/s3ql-docs/installation.html#dependencies
# https://github.com/s3ql/s3ql/blob/master/setup.py#L138
RUN set -e -x \
    && pip --no-cache-dir install -U \
        'pyfuse3 >= 1.0, < 2.0' \
        cryptography requests defusedxml \
        'dugong >= 3.4, < 4.0' \
        google-auth google-auth-oauthlib \
        'pytest >= 3.7' 'trio >= 0.9, < 0.12' pytest_trio \
        'cython >= 0.24' 'sphinx >= 1.2b1' \
        async_generator
        # trio < 0.12 issue: https://github.com/s3ql/s3ql/issues/134

# Tests
CMD set -e -x \
    && git clone https://github.com/s3ql/s3ql.git \
    && cd s3ql/ \
    && python setup.py build_cython \
    && python setup.py build_ext --inplace \
    && python -m pytest tests/ \
    && python setup.py build_sphinx \
    && python setup.py install \
    && echo "OK."
