Package: pkg-name
Version: ${upstream_version}[-${debian_revision}]~bpo${debian_release}+${build_int}
Section: section
Priority: extra
Architecture: amd64
Maintainer: Viktor Szépe <viktor@szepe.net>
Homepage: https://
Description: First line.
 Second line.

# https://www.debian.org/doc/debian-policy/ch-controlfields.html#s-binarycontrolfiles
Package: jpeg-archive

# https://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version
# http://backports.debian.org/Contribute/#index6h3
# unofficial:  ${upstream_version}[-${debian_revision}]
# backport:    ${upstream_version}[-${debian_revision}]~bpo${debian_release}+${build_int}
# development: ${upstream_version}[-${debian_revision}]~dev${build_int}
Version: 1.2.3-4~bpo8+1

# https://packages.debian.org/unstable/
# for main: <section>
# for contrib and non-free areas: <area>/<section>
Section: graphics

# https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities
# required | important | standard | optional | extra
Priority: extra

# all | amd64
Architecture: amd64

# https://www.debian.org/doc/debian-policy/ch-relationships.html
Depends: libsomethingorrather (>= 1.2.13), anotherDependency (= 1.2.6)
Pre-Depends:
Recommends:
Suggests:
Enhances:
Breaks:
# "a stronger restriction than Breaks"
Conflicts:
# "Virtual packages"
Provides:
Replaces:

Maintainer: Viktor Szépe <viktor@szepe.net>

Description: Utilities for archiving JPEGs for long term storage.
 Additional lines must begin with a space.

# "the site from which the original source can be obtained"
Homepage:

# "Additional source packages used to build the binary"
Built-Using:

#dh_make --createorig --single
#dpkg-deb --build helloworld_1.0-1
