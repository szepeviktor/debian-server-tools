# About Watcher

Watcher is a daemon that watches specified files/folders for changes and
fires commands in response to those changes. It is similar to
[incron](http://incron.aiken.cz), however, configuration uses a simpler
to read ini file instead of a plain text file. Unlike incron it can also
recursively monitor directories.

It's written in Python, making it easier to hack.

This fork is a rewritting of the code using python-daemon implementation of [PEP3143](http://legacy.python.org/dev/peps/pep-3143/) 

## Requirements

You need Python 2.7 and the following modules that can be installed with `pip`:

* [pyinotify](http://github.com/seb-m/pyinotify)
* [python-daemon](https://alioth.debian.org/projects/python-daemon/)
* [lockfile](https://launchpad.net/pylockfile)

To install `pip` on Ubuntu:

    sudo apt-get install pip

To install the modules:

    sudo pip install python-daemon lockfile pyinotify

For Python 3, install [python-daemon-3K](https://github.com/jbvsmo/python-daemon) instead of python-daemon:

    sudo pip install python-daemon-3K lockfile pyinotify

## Configuration

See the provided `watcher.ini` file for an example job configuration. The
config file should reside in `/etc/watcher.ini` or `~/.watcher.ini`. You
can also specify the path to the config file as a command line parameter
using the `--config` option.

If you edit the ini file you must restart the daemon for it to reload the
configuration.

## Starting the Daemon

Make sure watcher.py is marked as executable:

    chmod +x watcher.py


Start the daemon with:

    ./watcher.py start

Stop it with:

    ./watcher.py stop

Restart it with:

    ./watcher.py restart

If you don't want the daemon to fork to the background, start it with

    ./watcher.py debug

