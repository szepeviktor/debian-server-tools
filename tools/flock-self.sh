#!/bin/bash
#
# Flock on itself.
#

exec 200<$0

flock --nonblock 200 || exit 200

# Example
#
#     exec 200<$0
#     flock --nonblock 200 || exit 200
#     echo "Unique start ..."
#     sleep 5
#     echo "End."
