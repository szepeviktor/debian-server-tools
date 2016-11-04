# szepeviktor/python-llfuse-test
#
# szepeviktor/python:3.5.2-stretch is from https://github.com/docker-library/python/raw/master/3.5/Dockerfile
# Change to stretch and Add gpg dirmngr
#
# Build: docker build -t szepeviktor/python-llfuse-test:stretch-0.1.1 python-llfuse-test/
#
# Run: docker run --tty --rm --cap-add SYS_ADMIN --device /dev/fuse szepeviktor/python-llfuse-test:stretch-0.1.1

FROM szepeviktor/python:3.5.2-stretch

# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    fuse pkg-config libattr1-dev libfuse-dev mercurial \
    && rm -rf /var/lib/apt/lists/*
RUN pip install -U cython==0.24.1 sphinx pytest pytest-catchlog

# Tests
CMD hg clone https://bitbucket.org/nikratio/python-llfuse \
    && cd python-llfuse/ \
    && python setup.py build_cython \
    && sed -i '/__pyx_v_ret = readdir_r/i#pragma GCC diagnostic ignored "-Wdeprecated-declarations"' src/llfuse.c \
    && python setup.py build_ext --inplace \
    && python -m pytest test/ \
    && python setup.py build_sphinx \
    && python setup.py install \
    && echo "OK."
