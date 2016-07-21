#!/bin/sh

set -e

# https://github.com/jgonggrijp/pip-review
pip2 install --upgrade pip-review

cp -a /usr/local/bin/pip-review /usr/local/bin/pip-review-debian

patch /usr/local/bin/pip-review-debian ./pip-review-debian.patch
