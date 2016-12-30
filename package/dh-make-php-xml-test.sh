#!/bin/bash
#
# Test PECL package.xml.
#
# DEPENDS       :apt-get install dh-make-php

Phppkginfo() {
    local CMD="$1"

    echo -n "${CMD}="
    /usr/share/dh-make-php/phppkginfo . "$CMD" | head -n 5
    echo
}

test -r package.xml || exit 1

Phppkginfo version
Phppkginfo maintainers
Phppkginfo summary
Phppkginfo description
Phppkginfo packagerversion
Phppkginfo package
Phppkginfo release_license
Phppkginfo license
Phppkginfo date
Phppkginfo changelog
Phppkginfo hasphpscript
Phppkginfo all
