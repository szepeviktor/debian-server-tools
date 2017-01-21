# szepeviktor/python-s3ql-test
#
# szepeviktor/python:3.5.2-stretch is from https://github.com/docker-library/python/raw/master/3.5/Dockerfile
# Change to stretch and Add gpg dirmngr
#
# Build: docker build -t szepeviktor/python-s3ql-test:stretch-0.1.1 python-s3ql-test/
#
# Run: docker run --tty --rm --cap-add SYS_ADMIN --device /dev/fuse szepeviktor/python-s3ql-test:stretch-0.1.1

FROM szepeviktor/python:3.5.2-stretch

# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    fuse psmisc pkg-config libattr1-dev libfuse-dev libsqlite3-dev libjs-sphinxdoc mercurial \
    texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-generic-extra texlive-fonts-recommended \
    && rm -rf /var/lib/apt/lists/*
RUN pip install -U cython==0.24.1 sphinx pycrypto defusedxml requests \
    "llfuse >= 1.0, < 2.0" "dugong >= 3.4, < 4.0" "pytest >= 2.3.3" pytest-catchlog
# apsw must be the same version as libsqlite3
# dpkg-query --show --showformat="\${Version}" libsqlite3-dev | sed 's/-.*$/-r1/'
# "apsw == 3.15.0-r1" in stretch
RUN pip install -U "https://github.com/rogerbinns/apsw/releases/download/3.15.0-r1/apsw-3.15.0-r1.zip"

# Tests
# Add Backblaze B2 support patch https://github.com/s3ql/s3ql/pull/8
CMD hg clone https://bitbucket.org/nikratio/s3ql \
   && wget https://github.com/s3ql/s3ql/pull/8.patch \
    && cd s3ql/ \
   && patch -p 1 < ../8.patch \
    && python setup.py build_cython \
    && python setup.py build_ext --inplace \
    && python -m pytest tests/ \
    && python setup.py build_sphinx \
    && python setup.py install \
    && echo "OK."
