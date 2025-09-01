#!/bin/bash
#
# Install a single Python package under /opt directory
#
# VERSION       :0.2.0
# DATE          :2025-08-24
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/sbin/python-add-opt-package.sh

name="$1"
binary="${2:-$name}"

set -e

mkdir -p "/opt/${name}"
cd "/opt/${name}/"

pip3 install --no-cache-dir --ignore-installed --no-warn-script-location --prefix "/opt/${name}/" "${name}"

binary_path="/opt/${name}/local/bin/${binary}"
test -x "${binary_path}"

# Generate launcher
# shellcheck disable=SC2086
printf '#!/bin/bash\nPYTHONPATH="%s" exec %s "$@"\n' \
    /opt/${name}/local/lib/python3.*/dist-packages \
    "${binary_path}" \
    >"/usr/local/bin/${binary}"
chmod a+x "/usr/local/bin/${binary}"

echo "OK."
