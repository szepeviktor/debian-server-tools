#!/bin/bash

# Create mirror list for netselect-apt
<mirror-urls.txt xargs -I % bash -c "sed -e 's|@@MIRROR@@|%|' mirror-list.tpl" >netselect-apt.infile

# Select best mirror
netselect-apt --infile netselect-apt.infile
rm -f netselect-apt.infile sources.list
