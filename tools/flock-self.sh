#!/bin/bash --version
#
# Flock on itself.
#
# VERSION       :0.1.0

exec 200<"$0"

# Wait for other processes to finish
#     flock 200 || exit 200

flock --nonblock 200 || exit 200

# Example
#
#     exec 200<$0
#     flock --nonblock 200 || exit 200
#     echo "Unique start ..."
#     sleep 5
#     echo "End."
