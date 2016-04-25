This package provides sysv debian-compatible system startup script that restores ipset rules from a configuration file. It requires next packages to work:
	iptables-persistent
	ipset

To install script
	1) enable executable flag by chmod +x ipset-persistent
	2) move it into /etc/init.d/ dir
	3) enable autostart with
		update-rc.d ipset-persistent defaults
	4) save rules with
		/etc/init.d/ipset-persistent save
or use deb if you have Debian based system.

Usage:
	/etc/init.d/ipset-persistent start - load ipset rules
	/etc/init.d/ipset-persistent flush - flush ipset rules
	/etc/init.d/ipset-persistent save - save ipset rules
