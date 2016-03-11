debian-server-tools
===================

Various scripts and tools for mainly Debian servers

Check shell scripts: http://www.shellcheck.net/

Code styling: https://google.github.io/styleguide/shell.xml

Bashism: https://wiki.ubuntu.com/DashAsBinSh

### /backup

Tools related to archiving.

### /image

Tools related to image optimization.

### /input

Tools related to the terminal.

### /mail

Tools related to email account management.

### /monitoring

Tools related to server monitoring, alert and statistics emails.

### /mysql

Tools related to database management.

### /package

Tools related to Debian packages and general packaging.

### /security

Security and SSL certificate related tools.

### /tools

Various small tools.

### /webserver

Tools related to building webservers.

### Fast and safe transit of scripts (or any data) via copy&paste

##### Pack

```bash
cat <SCRIPT>|xz -9|base64 -w $((COLUMNS-1))
# alias: cat <SCRIPT>|transit
```

##### Unpack

```bash
cat <PASTED-FILE>|base64 -d|xz -d > <SCRIPT>
# alias: cat <PASTED-FILE>|transit-receive
```

### Flush Google public DNS cache

http://google-public-dns.appspot.com/cache

### Rescan the SCSI Bus to Add SCSI Devices

```bash
echo "- - -" > /sys/class/scsi_host/host0/scan
```

### geoipupdate with free GeoLite

```ini
UserId 999999
LicenseKey 000000000000
ProductIds 506 533
```

### Free CDN for GitHub

http://rawgit.com/ `https://cdn.rawgit.com/USER/REPO/TAG/FILE`

### Moving away git-dir

1. /home/user/website/work-dir/.git: `gitdir: /home/user/git`
1. /home/user/git/config: `[core]\n\tworktree = /home/user/website/work-dir`
