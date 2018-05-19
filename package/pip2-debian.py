#!/usr/bin/python2

import pkg_resources


for dist in pkg_resources.working_set:
    source = 'pip'
    if dist.location.startswith('/usr/lib/python'):
        source = 'Debian'
    print('%-20s\t%s' % (dist.project_name, source))
