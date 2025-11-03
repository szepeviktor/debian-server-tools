#!/bin/bash
#
# Display non-ASCII characters except an alphabet.
#
# VERSION       :0.2.0
# DATE          :2020-06-06
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DOCS          :http://jrgraphix.net/research/unicode_blocks.php
# LOCATION      :/usr/local/bin/non-ascii-hu.sh

FILE_GLOB="*.php"

# Hungarian alphabet
ALPHABET="ÁÉÍÓÖŐÚÜŰáéíóöőúüű"
# Euro sign
#ALPHABET+="€"
# Polish alphabet
#ALPHABET="ĄĆĘŁŃÓŚŹŻąćęłńóśźż"
# Czech alphabet
#ALPHABET="ÁČĎÉĚÍŇÓŘŠŤÚŮÝŽáčďéěíňóřšťúůýž"
# Croatian alphabet
#ALPHABET="ČĆĐŠŽčćđšž"

# UNICODE Latin-1 Supplement signs (00A1-00BF)
#ALPHABET="$(for C in A{{1..9},{A..F}} B{{0..9},{A..F}};do printf "\\x${C}\\x00";done|iconv -f UNICODE -t UTF-8)"
# UNICODE Latin-1 Supplement letter (00C0-00FF)
#ALPHABET="$(for C in {C..F}{{0..9},{A..F}};do printf "\\x${C}\\x00";done|iconv -f UNICODE -t UTF-8)"

# Russian alphabet
#ALPHABET="АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя"
# Russian alphabet from UNICODE Cyrillic (0410-042F 0430-044F + 0401 + 0451)
#ALPHABET="$(for C in {1..4}{{0..9},{A..F}} 01 51;do printf "\\x${C}\\x04";done|iconv -f UNICODE -t UTF-8)"

# Punctuation marks in documents
#PUNCTUATION_MARKS="’“”«»•…–"

# Search for non-ASCII characters
LC_ALL=C.UTF-8 find . -type f -name "${FILE_GLOB}" -exec \
    grep -PHn "[^ -~${ALPHABET}]" "{}" ";"
