#!/bin/sh
#
# Optimize images in the current directory.
# JPEG: decrease quality, make it progressive, strip markers
# PNG: lossless recompression, strip metadata
#
# DEPENDS :apt-get install jpeginfo
# SOURCE  :http://www.infai.org/jpeg/ (jpegtran)
# SOURCE  :https://github.com/rflynn/imgmin (imgmin)
# SOURCE  :http://optipng.sourceforge.net/ (optipng)


# JPEG images
NEW="$(tempfile).imageopti"

for JPG in *.jpg; do
    # error check
    jpeginfo --check "$JPG" | grep "\[OK\]\$" || exit 1

    if imgmin "$JPG" "$NEW"; then
        # convert to progressive, strip markers
        /usr/local/bin/jpegtran -perfect -optimize -progressive -outfile "$JPG" "$NEW" || exit 3
    else
        exit 2
    fi
    echo
done
[ -f "$NEW" ] && rm "$NEW"

# PNG images
[ -f *.png ] && /usr/local/bin/optipng074 -clobber -strip all -o7 *.png
