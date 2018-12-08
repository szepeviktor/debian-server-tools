#!/bin/bash
#
# Optimize images in WordPress Media Library cron job.
#
# VERSION       :0.5.3
# DATE          :2015-06-30
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install jpeginfo jpeg-archive optipng
# DEPENDS       :http://wp-cli.org/#install
# LOCATION      :/usr/local/bin/wp-media-optimize.sh

# Example system crontab line
#
# */5 *	* * *	USER	/usr/local/bin/wp-media-optimize.sh WP-ROOT

WP_ROOT="$1"
JPEG_RECOMPRESS="/usr/bin/jpeg-recompress --target 0.9995 --subsample disable --accurate --strip"
WP_CLI="/usr/local/bin/wp --quiet"
META_NAME="optimized"
LOGGER_TAG="$(basename --suffix=.sh "$0")"

Handle_error() {
    local MSG
    local RET="$1"
    local ITEM="$2"

    case "$RET" in
        1)
            MSG="Invalid JPEG image"
            ;;
        2)
            MSG="jpeg-recompress failure"
            ;;
        3)
            MSG="Failed move back optimized image"
            ;;
        4)
            MSG="Invalid image after jpeg-recompress"
            ;;
        10)
            MSG="optipng failure"
            ;;
        20)
            MSG="Empty image path"
            ;;
        21)
            MSG="Missing image"
            ;;
        *)
            MSG="Unknown error ${RET}"
            ;;
    esac
    echo "${MSG} (${ITEM})" 1>&2
}

Optimize_image() {
    local IMG="$1"
    local TMPIMG

    [ -z "$IMG" ] && return 20
    [ -f "$IMG" ] || return 21

    # JPEG
    if [ "$IMG" != "${IMG%.jpg}" ] || [ "$IMG" != "${IMG%.jpeg}" ]; then
        logger -t "$LOGGER_TAG" "JPEG:${IMG}"
        jpeginfo --check "$IMG" >/dev/null || return 1
        TMPIMG="$(mktemp)"
        # shellcheck disable=SC2086
        if ! nice ${JPEG_RECOMPRESS} --quiet "$IMG" "$TMPIMG"; then
            rm -f "$TMPIMG" &>/dev/null
            return 2
        fi
        if [ -f "$TMPIMG" ] && ! mv -f "$TMPIMG" "$IMG"; then
            rm -f "$TMPIMG"
            return 3
        fi
        jpeginfo --check "$IMG" >/dev/null || return 4
    fi

    # PNG
    if [ "$IMG" != "${IMG%.png}" ]; then
        logger -t "$LOGGER_TAG" "PNG:${IMG}"
        nice optipng -quiet -preserve -clobber -strip all -o7 "$IMG" || return 10
    fi

    # Optimized OK or other type of image.
    return 0
}

WP_CLI+=" --path=${WP_ROOT}"

if ! ${WP_CLI} core is-installed; then
    echo "This does not seem to be a WordPress install." 1>&2
    exit 1
fi

# shellcheck disable=SC2016
UPLOADS="$(${WP_CLI} eval '$u=wp_upload_dir(); echo $u["basedir"];')"

# Loop through all attachments without "optimized" metadata
for ATTACHMENT_ID in $(${WP_CLI} post list --format=ids --post_type=attachment \
        --post_status=inherit --meta_key="$META_NAME" --meta_compare="NOT EXISTS"); do
    ATTACHMENT_PATH="$(${WP_CLI} post meta get "$ATTACHMENT_ID" _wp_attached_file)"
    ATTACHMENT_FILE="$(basename "$ATTACHMENT_PATH")"

    tty --quiet && echo "${ATTACHMENT_ID} ..."

    # Find the image and all resized variations
    find "${UPLOADS}/$(dirname "${ATTACHMENT_PATH}")" \
        -regex ".*/${ATTACHMENT_FILE%.*}\\(-[0-9]+x[0-9]+\\)?\\.${ATTACHMENT_FILE##*.}" -print0 \
        | while read -d $'\0' -r ATTACHMENT; do
            if Optimize_image "$ATTACHMENT"; then
                ${WP_CLI} post meta set "$ATTACHMENT_ID" "$META_NAME" 1
            else
                Handle_error $? "$ATTACHMENT"
            fi
        done
done

exit 0
