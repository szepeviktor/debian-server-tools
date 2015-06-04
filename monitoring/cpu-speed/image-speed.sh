#!/bin/bash

# Test image conversion speed.
#
# DEPENDS: apt-get install unzip imgmin jpeg-archive

Download() {
    IMGMIN_API_CONTENT_URL="https://api.github.com/repos/rflynn/imgmin/contents/examples"
    JPEG_ARC_URL="https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip?dl=1"

    # MagickWand-config location: https://github.com/rflynn/imgmin/issues/51
    mkdir imgmin
    wget -qO- "$IMGMIN_API_CONTENT_URL" \
        | grep '    "download_url":' | grep -v -- '-after\.' | cut -d'"' -f4 \
        | wget -nv -N -P imgmin -i -

    mkdir jpeg-archive
    wget -nv -N -P jpeg-archive "$JPEG_ARC_URL"
    unzip jpeg-archive/jpeg-archive-test-files*.zip -d jpeg-archive
}

Download

mkdir results

# imgmin
time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    imgmin "$IMG" "results/imgmin-$(basename "$IMG")"
    echo
done

# jpeg-archive
time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    jpeg-recompress --quality low "$IMG" "results/jpeg-archive-$(basename "$IMG")"
    echo
done

du -ck results/imgmin-*
du -ck results/jpeg-archive-*
