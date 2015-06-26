#!/bin/bash
#
# Test image conversion speed.
#
# DEPENDS: apt-get install unzip jpeg-archive libmagickwand-6.q16-2 imgmin

Download() {
    IMGMIN_API_CONTENT_URL="https://api.github.com/repos/rflynn/imgmin/contents/examples"
    JPEG_ARC_URL="https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip?dl=1"

    # MagickWand-config location: https://github.com/rflynn/imgmin/issues/51
    mkdir imgmin
    wget -q -O- "$IMGMIN_API_CONTENT_URL" \
        | grep '    "download_url":' | grep -v -- '-after\.' | cut -d'"' -f4 \
        | wget -nv --content-disposition -N -P imgmin -i -

    mkdir jpeg-archive
    wget -nv --content-disposition -N -P jpeg-archive "$JPEG_ARC_URL"
    unzip jpeg-archive/jpeg-archive-test-files*.zip -d jpeg-archive
}

if ! [ -d jpeg-archive/test-files ] || ! [ -d imgmin ]; then
    Download
    mkdir results
fi

# imgmin
time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    imgmin "$IMG" "results/imgmin-$(basename "$IMG")"
    echo
done

sleep 4

# jpeg-archive
time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    jpeg-recompress --quality low "$IMG" "results/jpeg-archive-$(basename "$IMG")"
    echo
done

du -ck results/imgmin-*
du -ck results/jpeg-archive-*
rm -rf results/*
