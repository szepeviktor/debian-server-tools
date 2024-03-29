#!/bin/bash
#
# Install modern Python.
#

# https://www.python.org/downloads/
INSTALL_PYTHON_VERSION="3.7.11"

py_bin()
{
    local BIN="$1"

    shift
    PYENV_ROOT=/opt/pyenv PYENV_VERSION="${INSTALL_PYTHON_VERSION}" \
        "/opt/pyenv/versions/${INSTALL_PYTHON_VERSION}/bin/${BIN}" "$@"
}

# Prerequisites
apt-get install -y gcc libssl-dev liblzma-dev uuid-dev libffi-dev libreadline-dev libbz2-dev zlib1g-dev
##apt-get install libssl-dev/jessie-backports

# https://github.com/pyenv/pyenv-installer
wget -q -O- https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | PYENV_ROOT=/opt/pyenv bash

PYENV_ROOT=/opt/pyenv /opt/pyenv/bin/pyenv install "${INSTALL_PYTHON_VERSION}"
# See python-build.${TIMESTAMP}.log

# Upgrade pip
py_bin pip3 install --upgrade pip
# Add wheel support
py_bin pip3 install wheel

## Install automatoes
#py_bin pip3 install automatoes
## Check automatoes
#py_bin manuale -h

#py_make_link()
#{
#    local bin="$1"
#    local bin_path="/usr/local/bin/${bin}"
#
#    echo "Creating link ${bin_path} ..."
#    printf 'PYENV_ROOT=/opt/pyenv PYENV_VERSION="%s" exec /opt/pyenv/versions/%s/bin/%s "$@"' >>"${bin_path}" \
#        "${INSTALL_PYTHON_VERSION}" "${INSTALL_PYTHON_VERSION}" "${bin}"
#    chmod +x "${bin_path}"
#}
## Link all S3QL commands
#py_bin pip3 install s3ql
#for bin in /opt/pyenv/versions/${INSTALL_PYTHON_VERSION}/bin/*s3ql*; do
#    py_make_link "${bin##*/}"
#done
