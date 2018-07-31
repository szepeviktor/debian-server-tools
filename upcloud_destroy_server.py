#!/usr/bin/env python3
#
# Destroy a populated instance at UpCloud by IP address.
#
# pip3 install --user upcloud-api
# chmod 0700 ./upcloud_destroy_server.py
# ./upcloud_destroy_server.py IP-ADDRESS

import sys
from upcloud_api import CloudManager


# EDIT here
manager = CloudManager('USERNAME', 'PASSWORD')

manager.authenticate()

populated_server = manager.get_server_by_ip(sys.argv[1])
populated_server.stop_and_destroy()
