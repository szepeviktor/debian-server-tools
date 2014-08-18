#!/bin/sh

# pip install pip-tools --upgrade

cp -a /usr/local/bin/pip-review /usr/local/bin/pip-review-debian
patch /usr/local/bin/pip-review-debian ./pip-review-debian.patch

