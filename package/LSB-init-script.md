# LSB Init Script

## For executables

### Features

- Takes (last) /usr/share/debhelper/dh_make/debian/init.d.ex as a base (contains /etc/init.d/skeleton)
- Includes LSB headers
- Runs on any shell
- shellcheck OK
- Takes /etc/init.d/skeleton as a base
- No `set -e`
- Uses /lib/lsb/init-functions
- Reads config file in /etc/defaults/
- Handles PID file
- Log messages appear only on `VERBOSE=yes`
- Proper exit status codes
- Does not run with Upstart
- Includes installation instructions

@TODO: introduce `start_daemon` where possible

## For interpreted languages

@TODO
