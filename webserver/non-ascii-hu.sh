#!/bin/bash
#
# Display non-ASCII characters except an alphabet.
#
# VERSION       :0.1.0
# DATE          :2018-08-17
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://jrgraphix.net/research/unicode_blocks.php
# LOCATION      :/usr/local/bin/non-ascii-hu.sh

FILE_GLOB="*.php"
# Hungarian
ALPHABET="áÁéÉíÍóÓöÖőŐúÚüÜűŰ"

# Latin-1 Supplement signs (00A1-00BF)
#ALPHABET="$(for C in A{1..9} A{A..F} B{0..9} B{A..F};do printf "\\x${C}\\x00";done|iconv -f UNICODE -t UTF-8)"
# Latin-1 Supplement letter (00C0-00FF)
#ALPHABET="$(for P in {C..F};do for C in ${P}{0..9} ${P}{A..F};do printf "\\x${C}\\x00";done;done|iconv -f UNICODE -t UTF-8)"

# Russian
#ALPHABET="АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя"
# Russian from Cyrillic (0410-042F 0430-044F + 0401 + 0451)
#ALPHABET="$({ for P in {1..4};do for C in ${P}{0..9} ${P}{A..F};do
#  printf "\\x${C}\\x04";done;done;printf '\x01\x04\x51\x04'; }|iconv -f UNICODE -t UTF-8)"

# Remove exceptions, thus the alphabet
find . -type f -name "$FILE_GLOB" -exec \
    sed -e "s#[${ALPHABET}]#A#g" -i "{}" ";"
# Search for non-ASCII characters
LC_ALL=C find . -type f -name "$FILE_GLOB" -exec \
    grep -H -n -P '[\x80-\xFF]' "{}" ";"
