#!/bin/bash
#
# Display chrony statistics in a tabular form.
#
# VERSION       :1.0.0
# DATE          :2025-03-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# LOCATION      :/usr/local/bin/chrony-stats.sh

grep --invert-match --line-regexp '=\+' /var/log/chrony/statistics.log \
    | sed -e 's#^\s*Date.*#Date Time IP_Address Std_dev Est_offset Offset_sd Diff_freq Est_skew Stress Ns Bs Nr Asym#' \
    | column --table
