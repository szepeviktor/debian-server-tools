#!/usr/bin/env python3
#
# Create a new instance at UpCloud.
#
# pip3 install --user upcloud-api
# chmod 0700 ./upcloud_create_server.py

from upcloud_api import CloudManager, Server, Storage, ZONE, login_user_block


# EDIT here
manager = CloudManager('USERNAME', 'PASSWORD')

user_viktor = login_user_block(
    username='root',
    ssh_keys=['ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJnaM2JLvO4DWkmmSXys+jn0KhTRVkCfAAhv/1Pszs0DJTheQgOR9e3ThNCgR7CxIqZ5kXrZ+BIDtDs5IGrg9IA= szv-ecdsa'],
    create_password=False
)

new_server_config = Server(
    hostname='upcloud.keszul.tk',
    zone=ZONE.Frankfurt,
    plan='2xCPU-4GB',
    storage_devices=[
        Storage(os='Debian 9.0', size=80)
    ],
    login_user=user_viktor,
    # Docker + pip
    user_data='https://github.com/szepeviktor/debian-server-tools/raw/master/debian-setup/upcloud-init.sh'
)

manager.authenticate()
new_server = manager.create_server(new_server_config)

# Print IP
print(new_server.get_public_ip() + '\n')
