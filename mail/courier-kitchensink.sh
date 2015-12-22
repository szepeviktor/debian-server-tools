#!/bin/bash
#
# Kitchen sink for Courier
#
# "If the external command terminates with the exit code of 99,
#  any additional delivery instructions in the file are NOT executed,
#  but the message is considered to be successfully delivered."
# http://www.courier-mta.org/dot-courier.html

cat > /dev/null

exit 99
