# Bandwidth

A memory bandwidth benchmark. http://zsmith.co/bandwidth.html

1. Download tar from https://mutineer.org/project.php?p=bandwidth
1. Dependencies `apt-get install -y build-essential nasm`
1. Build `make bandwidth64`
1. Run `nice -n -2 ./bandwidth64 --fast`

It produces a BMP image.
