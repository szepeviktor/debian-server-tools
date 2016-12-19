debian-server-tools
===================

Various scripts and tools mainly for Debian servers.

### Model of how systems work

[Richard Cook at Velocity NY 2013](https://youtu.be/PGLYEDpNu60?t=5m44s)

### Debian install with UTC as timezone

Select Expert install.

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

### /virtualization

Docker containers.

### /webserver

Tools related to building webservers.

### Script development

- Check shell scripts: http://www.shellcheck.net/
- Code styling: https://google.github.io/styleguide/shell.xml
- Bashism: https://wiki.ubuntu.com/DashAsBinSh `checkbashisms -f bash-script.sh`

### How to choose VPS provider?

See https://github.com/szepeviktor/wordpress-speedtest/blob/master/README.md#how-to-choose-vps-provider

### Install your own SSH key

```bash
S="${HOME}/.ssh";mkdir --mode 0700 "$S";editor "${S}/authorized_keys2"
```

Parameters

```
no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"debian\" rather than the user \"root\".';echo;sleep 10" ssh-rsa AAAA...
```

### Install a user's SSH key

```bash
U="$(stat -c %U .)";S="$(getent passwd $U|cut -d: -f6)/.ssh";mkdir --mode 0700 "$S";editor "${S}/authorized_keys2";chown -R $U:$U "$S"
```

### Fast and safe transit of scripts (or any data) via copy&paste

##### Pack

```bash
cat $SCRIPT|xz -9|base64 -w $((COLUMNS-1))
# alias: cat $SCRIPT|transit
```

##### Unpack

```bash
cat $PASTED_FILE|base64 -d|xz -d > $SCRIPT
# alias: cat $PASTED_FILE>|transit-receive
```

### Moving away git-dir

`git init --separate-git-dir=/home/user/gitdir`

Produces:

/home/user/work-dir/.git: `gitdir: /home/user/git`

/home/user/gitdir/config: `worktree = /home/user/work-dir`

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

### Flush Google public DNS cache

http://google-public-dns.appspot.com/cache

### Free CDN for GitHub

http://rawgit.com/ `https://cdn.rawgit.com/USER/REPO/TAG/FILE`

### UNICODE owl domain name

[﴾͡๏̯͡๏﴿.tk](http://xn--wta3hb403ica11187ama.tk/)

### Crontab format

```
.---------------- minute (0 - 59)
| .-------------- hour (0 - 23)
| |  .----------- day of month (1 - 31)
| |  | .--------- month (1 - 12)
| |  | | .------- day of week (0 - 6)
| |  | | |
* *  * * *  USER  COMMAND
```

```
crontab -e -u USER
.---------------- minute (0 - 59)
| .-------------- hour (0 - 23)
| |  .----------- day of month (1 - 31)
| |  | .--------- month (1 - 12)
| |  | | .------- day of week (0 - 6)
| |  | | |
* *  * * *  COMMAND
```

### Writing a man page

http://asciidoc.org/
