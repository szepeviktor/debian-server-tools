#!/bin/bash
#
# Test an IP list against FireHOL blocklists
#

# FireHOL Level 1 = openbl_1d dshield_1d blocklist_de stopforumspam_1d botscout_1d greensnow

# List of IP addresses and IP ranges in CIDR notation
ls *.ipset *.netset | xargs -I %% bash -c "echo -n '%% ';grepcidr -c -f %% ../banned-IP-s.list" | sort -n -k2
