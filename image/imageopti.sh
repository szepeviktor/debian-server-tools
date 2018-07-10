#!/bin/bash
#
# Optimize images in the current directory.
#
# VERSION       :0.5.1
# DATE          :2018-01-02
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install jpeginfo jpeg-archive pngcheck optipng
# DEPENDS       :npm install svgo
# LOCATION      :/usr/local/bin/imageopti.sh

# For JPEG images: decrease quality, make it progressive, strip markers
# For PNG images: lossless recompression, strip metadata
# For SVG images: all svgo plugins - https://github.com/svg/svgo

Optimize_jpeg()
{
    local INPUT="$1"
    local OUTPUT="$2"

    # Check JPEG for errors
    if ! jpeginfo --check "$INPUT" | grep '\[OK\]$'; then
        return 1
    fi

    if ! jpeg-recompress --quiet --target 0.9995 --subsample disable --accurate --strip "$INPUT" "$OUTPUT"; then
        return 2
    fi

    return 0
}

Optimize_png()
{
    local INPUT="$1"
    local OUTPUT="$2"

    # Check PNG for errors
    if ! pngcheck "$INPUT" | grep '^OK:'; then
        return 1
    fi

    if ! optipng -force -quiet -clobber -preserve -strip all -o7 -out "$OUTPUT" "$INPUT"; then
        return 2
    fi

    return 0
}

Optimize_svg()
{
    local INPUT="$1"
    local OUTPUT="$2"

    #if ! xmllint "$INPUT" > /dev/null; then
    #    return 1
    #fi

    if ! svgo --quiet --multipass -i "$INPUT" -o "$OUTPUT"; then
        return 2
    fi

    return 0
}

Optimize_image()
{
    local IMAGE="$1"
    local TMPIMG
    local -i STATUS_CODE="0"

    TMPIMG="$(mktemp --suffix=.imageopti)"

    case "${IMAGE##*.}" in
        jpg|jpeg)
            Optimize_jpeg "$IMAGE" "$TMPIMG" || STATUS_CODE="$?"
            ;;
        png)
            Optimize_png "$IMAGE" "$TMPIMG" || STATUS_CODE="$?"
            ;;
        svg)
            Optimize_svg "$IMAGE" "$TMPIMG" || STATUS_CODE="$?"
            ;;
        *)
            # Unknown file extension
            rm "$TMPIMG"
            return 0
            ;;
    esac

    # Failed optimization
    if [ "$STATUS_CODE" -ne 0 ]; then
        echo "${IMAGE}: Optimization ERROR #${STATUS_CODE}" 1>&2
        return "$STATUS_CODE"
    fi

    # Empty image
    if [[ -f "$TMPIMG" && ! -s "$TMPIMG" ]]; then
        echo "${IMAGE}: Empty image after optimization" 1>&2
        rm "$TMPIMG"
        return 3
    fi

    # Cannot overwrite original image
    if ! mv -f "$TMPIMG" "$IMAGE"; then
        rm "$TMPIMG"
        return 4
    fi

    return 0
}

declare -i FAILURES="0"

set -e

if [[ $EUID -eq 0 ]]; then
    "Don't run this script as root." 1>&2
    exit 100
fi

while IFS="" read -r -d $'\0' IMAGE; do
    Optimize_image "$IMAGE" || FAILURES+="1"
done < <(find . -type f -print0)

echo "OK. Total failures: ${FAILURES}"
