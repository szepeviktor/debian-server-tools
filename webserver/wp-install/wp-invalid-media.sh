#!/bin/bash
#
# Find WordPress media with non-slug filename.
#
# VERSION       :0.1.0

set -e

find "$(wp eval 'echo wp_upload_dir()["basedir"];')" -type f -regex '.*[^/0-9A-Za-z._-].*'
