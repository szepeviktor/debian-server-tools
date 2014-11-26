#!/bin/sh
#
# Optimize images in the current directory.
# JPEG: decrease quality, make it progressive, strip markers
# PNG: lossless recompression, strip metadata
#
# DEPENDS :apt-get install libjpeg8 libmagickwand5 jpeginfo
# SOURCE  :http://www.infai.org/jpeg/ (jpegtran)
# SOURCE  :https://github.com/rflynn/imgmin (imgmin)
# SOURCE  :http://optipng.sourceforge.net/ (optipng)

Build_jpeg() {
    local JPEG_SITE="http://www.infai.org/jpeg/"
    local JPEG_URL="$(wget -qO- "$JPEG_SITE"|grep -o 'http://www\.infai\.org/jpeg/files?get=jpegsrc\.[^"]*\.tar\.gz')"

    [ -z "$JPEG_URL" ] && exit 10
    wget -nv -O jpegsrc.tar.gz "$JPEG_URL"
    tar xf jpegsrc.tar.gz
    pushd jpeg-*
    ./configure && make && make install || exit 11
    popd

    # system-wide change
    #echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local.conf
    #ldconfig

    pushd /usr/local
    # `/usr/lib/libjpeg.*' -> `/usr/local/lib/libjpeg.*'
    find lib -name "libjpeg.*" -exec ln -sv /usr/local/\{\} /usr/\{\} \;
    popd

    [ -x /usr/local/bin/jpegtran ] || exit 12
    # accepts no --version
    #/usr/local/bin/jpegtran --version || exit 13
}

Build_imgmin() {
    local IMGMIN_URL="https://github.com/rflynn/imgmin/archive/master.tar.gz"

    apt-get install -y libmagickwand-dev
    wget -nv -O imgmin.tar.gz "$IMGMIN_URL"
    tar xf imgmin.tar.gz
    pushd imgmin-master/
    # don't build mod_imgmin
    # configure.ac / AC_CONFIG_FILES
    sed -i 's|src/apache2/Makefile||' configure.ac
    # src/Makefile.am / bin_PROGRAMS
    sed -i 's|mod_imgmin||' src/Makefile.am
    autoreconf -fi && ./configure && make && make install || exit 14
    popd

    [ -x /usr/local/bin/imgmin ] || exit 14
    /usr/local/bin/imgmin --help || exit 15
}

Install_optipng() {
    OPTIPNG_URL="http://mirror.szepe.net/debian/pool/main/o/optipng/optipng_0.7.5-1~bpo70+1_amd64.deb"

    apt-get install -y libpng12-0 zlib1g
    wget "$OPTIPNG_URL"
    dpkg -i optipng_*_amd64.deb

    [ -x /usr/bin/optipng ] || exit 16
    optipng --version || exit 17
}

Build_all() {
    which autoconf make gcc &> /dev/null || exit 99
    apt-get install -y libjpeg8 libmagickwand5 jpeginfo
    Build_jpeg
    Build_imgmin
    Install_optipng
}

Install_all() {
    apt-get install -y libjpeg8 libmagickwand5 jpeginfo

    # /usr/local/lib/libjpeg.a
    # /usr/local/lib/libjpeg.la
    # /usr/local/lib/libjpeg.so
    # /usr/local/lib/libjpeg.so.9
    # /usr/local/lib/libjpeg.so.9.1.0
    # /usr/local/bin/jpegtran
    # /usr/local/bin/cjpeg
    # /usr/local/bin/djpeg
    # /usr/local/bin/imgmin
    tar -xvf image.tar

    pushd /usr/local
    # `/usr/lib/libjpeg.*' -> `/usr/local/lib/libjpeg.*'
    find lib -name "libjpeg.*" -exec ln -sv /usr/local/\{\} /usr/\{\} \;
    popd

    Install_optipng
}

Optimize_jpeg() {
    local NEW="$(tempfile).imageopti"

    for JPG in *.jpg; do
        # error check
        jpeginfo --check "$JPG" | grep "\[OK\]$" || exit 1

        if imgmin "$JPG" "$NEW"; then
            # make it progressive, strip markers
            jpegtran -perfect -optimize -progressive -outfile "$JPG" "$NEW" || exit 3
        else
            echo "Minification error: $?" >&2
            exit 1
        fi
        echo
    done
    [ -f "$NEW" ] && rm "$NEW"
}

Optimize_png() {
    optipng -clobber -strip all -o7 *.png
}

# build and install tools
#Build_all; exit

# install tools
#Install_all; exit

# run-time dependency
ldd /usr/local/bin/imgmin | grep -q "not found" && exit 99
which jpeginfo &> /dev/null || exit 99

ls *.jpg &> /dev/null && Optimize_jpeg
ls *.png &> /dev/null && Optimize_png
find -maxdepth 1 -type f -iname "*.jpeg" && echo "ERROR: non-jpeg extension"
