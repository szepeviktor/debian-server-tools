#!/bin/bash
#
# List WP-Cron events without registered hooks.
#
# VERSION       :0.1.0

set -e

wp eval 'array_map(function($c){$h=array_key_first($c);if(!has_action($h))echo $h,"\n";},_get_cron_array());'
