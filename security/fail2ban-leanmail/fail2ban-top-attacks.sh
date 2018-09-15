#!/bin/bash
#
# List attack types and counts.
#

{
    logsearch.sh -e 404_not_found | grep -o '404_not_found'
    logsearch.sh -e 403_forbidden | grep -o '403_forbidden'
    logsearch.sh -e bad_request | grep -o 'bad_request\S\+'
    logsearch.sh -e no_wp_here | grep -o 'no_wp_here\S\+'
    logsearch.sh -e wpf2b | grep -o 'wpf2b\S\+'
} | sort | uniq -c
