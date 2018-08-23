#
# szepeviktor/python-s3ql-test-b2
#
# BUILD         :docker build -t szepeviktor/python-s3ql-test-b2 .
# RUN           :docker run --tty --rm --cap-add SYS_ADMIN --device /dev/fuse szepeviktor/python-s3ql-test-b2

FROM szepeviktor/python:3.5.6-stretch

# Dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fuse psmisc pkg-config libattr1-dev libfuse-dev libsqlite3-dev libjs-sphinxdoc mercurial \
        texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-generic-extra texlive-fonts-recommended \
    && rm -rf /var/lib/apt/lists/*

# apsw must be the same version as libsqlite3
# https://packages.debian.org/stretch/libsqlite3-dev
#     dpkg-query --show --showformat='${Version}' libsqlite3-dev | sed -e 's#-.*$#-r1#'
# apsw==3.16.2-r1 in stretch
RUN pip install -U "https://github.com/rogerbinns/apsw/releases/download/3.16.2-r1/apsw-3.16.2-r1.zip"

# http://www.rath.org/s3ql-docs/installation.html#dependencies
# https://github.com/s3ql/s3ql/blob/master/setup.py#L132
RUN pip install -U \
        "cython >= 0.24.1" "sphinx >= 1.2b1" "pytest >= 2.7" \
        pycrypto requests defusedxml "dugong >= 3.4, < 4.0" "llfuse >= 1.0, < 2.0"

# Tests
#       Add Backblaze B2 support patch https://github.com/s3ql/s3ql/pull/8
CMD git clone https://github.com/s3ql/s3ql.git \
        && wget https://github.com/s3ql/s3ql/pull/8.patch \
    && cd s3ql/ \
        && patch -p 1 < ../8.patch \
    && python setup.py build_cython \
    && python setup.py build_ext --inplace \
    && python -m pytest tests/ \
    && python setup.py build_sphinx \
    && python setup.py install \
    && echo "OK."
