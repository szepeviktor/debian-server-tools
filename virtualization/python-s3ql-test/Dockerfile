#
# szepeviktor/python-s3ql-test
#
# BUILD         :docker build -t szepeviktor/python-s3ql-test:stretch-0.2.1 .
# RUN           :docker run --tty --rm --cap-add SYS_ADMIN --device /dev/fuse szepeviktor/python-s3ql-test:stretch-0.2.1

FROM szepeviktor/python:3.5.7-stretch

# Dependencies
RUN set -e -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        fuse psmisc pkg-config libattr1-dev libfuse-dev libsqlite3-dev libjs-sphinxdoc mercurial \
        texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-generic-extra texlive-fonts-recommended

RUN set -e -x \
    && apt-get --purge -y autoremove \
    && apt-get clean \
    && find /var/lib/apt/lists -type f -delete

# apsw must be the same version as libsqlite3
# https://packages.debian.org/stretch/libsqlite3-dev
#     dpkg-query --show --showformat='${Version}' libsqlite3-dev | sed -e 's#-.*$#-r1#'
# apsw==3.16.2-r1 in stretch
RUN set -e -x \
    && pip install -U "https://github.com/rogerbinns/apsw/releases/download/3.16.2-r1/apsw-3.16.2-r1.zip"

# http://www.rath.org/s3ql-docs/installation.html#dependencies
# https://github.com/s3ql/s3ql/blob/master/setup.py#L143
RUN set -e -x \
    && pip install -U \
        cryptography requests defusedxml \
        'dugong >= 3.4, < 4.0' 'llfuse >= 1.0, < 2.0' \
        google-auth google-auth-oauthlib \
        'pytest >= 3.7' 'cython >= 0.24' 'sphinx >= 1.2b1'

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
