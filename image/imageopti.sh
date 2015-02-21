#!/bin/sh
#
# Optimize all images in the current directory.
# JPEG: decrease quality, make it progressive, strip markers
# PNG: lossless recompression, strip metadata
#
# VERSION       :0.3
# DATE          :2015-02-20
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/imageopti.sh
# DEPENDS       :apt-get install libmagickwand5 jpeginfo
# SOURCE        :http://www.infai.org/jpeg/ (jpeg progs)
# SOURCE        :https://github.com/rflynn/imgmin (imgmin)
# SOURCE        :http://optipng.sourceforge.net/ (optipng)

# Usage cases:
# imageopti.sh -build
# imageopti.sh -install
# find wp-content/uploads/ -type d '(' -print -a -exec bash -c "cd {};imageopti.sh" ';' -o -quit ')'

Build_jpeg() {
    local JPEG_SITE="http://www.infai.org/jpeg/"
    local JPEG_URL="$(wget -qO- "$JPEG_SITE"|grep -o 'http://www\.infai\.org/jpeg/files?get=jpegsrc\.[^"]*\.tar\.gz')"

    [ -z "$JPEG_URL" ] && exit 10
    wget -nv -O jpegsrc.tar.gz "$JPEG_URL"
    tar xf jpegsrc.tar.gz
    pushd jpeg-*
    ./configure && make && make install || exit 11
    popd

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

Install_jpeg() {
    JPEG_URL="http://szepeviktor.github.io/debian/pool/main/libj/libjpeg9/libjpeg9_9a-2~bpo70+1_amd64.deb"
    JPEG_PROGS_URL="http://szepeviktor.github.io/debian/pool/main/libj/libjpeg9/libjpeg-progs_9a-2~bpo70+1_amd64.deb"

    wget -nv -O libjpeg_amd64.deb "$JPEG_URL"
    wget -nv -O libjpeg-progs_amd64.deb "$JPEG_PROGS_URL"
    dpkg -i libjpeg_amd64.deb libjpeg-progs_amd64.deb

    [ -x /usr/bin/jpegtran ] || exit 16
    # accepts no --version
    #/usr/bin/jpegtran --version || exit 17
}

Install_imgmin() {
    IMGMIN_URL="http://szepeviktor.github.io/debian/pool/main/i/imgmin/imgmin_1.0-1_amd64.deb"

    apt-get install -y libgomp1 libmagickcore5 libmagickwand5
    wget -nv -O imgmin_amd64.deb "$IMGMIN_URL"
    dpkg -i imgmin_amd64.deb

    [ -x /usr/bin/imgmin ] || exit 18
    /usr/bin/imgmin --help || exit 19
}

Install_optipng() {
    OPTIPNG_URL="http://szepeviktor.github.io/debian/pool/main/o/optipng/optipng_0.7.5-1~bpo70+1_amd64.deb"

    apt-get install -y libpng12-0 zlib1g
    wget -nv -O optipng_amd64.deb "$OPTIPNG_URL"
    dpkg -i optipng_amd64.deb

    [ -x /usr/bin/optipng ] || exit 20
    optipng --version || exit 21
}

Build_all() {

    which autoconf make gcc &> /dev/null || exit 99
    apt-get install -y libmagickwand5 jpeginfo
    jpeginfo --version

    Build_jpeg
    # /usr/local/lib/libjpeg.a
    # /usr/local/lib/libjpeg.la
    # /usr/local/lib/libjpeg.so
    # /usr/local/lib/libjpeg.so.9
    # /usr/local/lib/libjpeg.so.9.1.0
    # /usr/local/bin/jpegtran
    # /usr/local/bin/cjpeg
    # /usr/local/bin/djpeg

    Build_imgmin
    # /usr/local/bin/imgmin

    Install_optipng
}

Install_all() {
    apt-get install -y jpeginfo
    jpeginfo --version

    Install_jpeg
    Install_imgmin
    Install_optipng
}

Optimize_jpeg() {
    local NEW="$(tempfile).imageopti"

    for JPG in *.jpg; do
        # error check
        jpeginfo --check "$JPG" | grep "\[OK\]$" || exit 1

        if nice "$IMGMIN" "$JPG" "$NEW"; then
            # make it progressive, strip markers
            jpegtran -perfect -optimize -progressive -copy none -outfile "$JPG" "$NEW" || exit 3
        else
            echo "Minification error: $?" >&2
            exit 1
        fi
        echo
    done
    [ -f "$NEW" ] && rm "$NEW"
}

Optimize_png() {
    nice optipng -clobber -strip all -o7 *.png
}

# build and install tools
if [ "$1" == "-build" ]; then
    Build_all
    exit
fi

# install tools
if [ "$1" == "-install" ]; then
    Install_all
    exit
fi

# run-time dependency
IMGMIN="$(which imgmin)"
ldd "$IMGMIN" | grep -q "not found" && exit 99
which jpeginfo &> /dev/null || exit 99

ls *.jpg &> /dev/null && Optimize_jpeg
ls *.png &> /dev/null && Optimize_png
find -maxdepth 1 -type f | grep -i "\.jpeg$" && echo "ERROR: '.jpeg' extension"
