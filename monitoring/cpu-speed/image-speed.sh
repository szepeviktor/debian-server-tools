#!/bin/bash


Download() {
    IMGMIN_BASE_URL="https://github.com/rflynn/imgmin/raw/e64807bc613ef0310910a5030ed4e5bd8bfeeefc/examples/"
    JPEG_ARC_URL="https://www.dropbox.com/s/hb3ah7p5hcjvhc1/jpeg-archive-test-files.zip?dl=1"

    # https://github.com/rflynn/imgmin/issues/51
    mkdir imgmin
    cat << IMGS | wget -nv -N --base=${IMGMIN_BASE_URL} -P imgmin -i -
Afghan-Girl-by-Steve-McCurry.jpg
Blue-Marble.jpg
VJ-Day-Kiss-Jorgensen.jpg
africa-dream-safaris.jpg
gradient-linear.jpg
imgmin-logo90.png
lena1.jpg
parrot-red-color-bird.jpg
IMGS

    mkdir jpeg-archive
    wget -nv -N -P jpeg-archive "$JPEG_ARC_URL"
    unzip jpeg-archive/jpeg-archive-test-files*.zip -d jpeg-archive
}

Download

mkdir results
time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    imgmin "$IMG" "results/imgmin-$(basename "$IMG")"
    echo
done

time for IMG in imgmin/*.jpg jpeg-archive/test-files/*.jpg; do
    echo "${IMG} ..."
    jpeg-recompress --quality low "$IMG" "results/jpeg-archive-$(basename "$IMG")"
    echo
done

du -ck results/imgmin-*
du -ck results/jpeg-archive-*
