#!/sbin/runscript
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/zabbix/files/2.2/init.d/zabbix-agentd,v 1.1 2013/11/16 07:18:54 mattm Exp $

pid_file="/run/watcher.pid"
config_file="/etc/watcher.ini"
daemon_bin="/usr/local/bin/watcher.py"

start_pre() {
	checkpath -d -m 0775 -o root:wheel /var/log/watcher
}

start() {
	ebegin "Starting inotify watcher"
	start-stop-daemon --start --pidfile ${pid_file} \
	    --exec $daemon_bin -- -c $config_file -v start
	eend $?
}

stop() {
	ebegin "Stopping inotify watcher"
	start-stop-daemon  --stop --pidfile ${pid_file}
	eend $?
}
