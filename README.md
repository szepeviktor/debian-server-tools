Debian server tools
===================

Various scripts and tools mainly for Debian servers.

### World&#39;s fastest cloud servers

Install Debian on [**UpCloud**](https://www.upcloud.com/register/?promo=U29Q8S)

### How to choose VPS provider?

See https://github.com/szepeviktor/wordpress-speedtest/blob/master/README.md#how-to-choose-vps-provider

### Model of how systems work

[Richard Cook at Velocity NY 2013](https://youtu.be/PGLYEDpNu60?t=5m44s)

### Debian install with UTC as timezone

Select Expert install.

### Directories

- /backup - Tools related to archiving
- /image - Tools related to image optimization
- /input - Tools related to the terminal
- /mail - Tools related to email account management
- /monitoring - Tools related to server monitoring, alert and statistics emails
- /mysql - Tools related to database management
- /package - Tools related to Debian packages and general packaging
- /security - Security and SSL certificate related tools
- /tools - Various small tools
- /virtualization - Docker containers
- /webserver - Tools related to building webservers

### Script development

- Check shell scripts: http://www.shellcheck.net/
- Code styling: https://github.com/git/git/blob/master/Documentation/CodingGuidelines
- Bashism: https://wiki.ubuntu.com/DashAsBinSh `checkbashisms -f bash-script.sh`

### Install your own SSH key

```bash
S="${HOME}/.ssh";mkdir --mode 0700 "$S";editor "${S}/authorized_keys"
ssh-keygen -v -l -f "${S}/authorized_keys"
```

`authorized_keys` parameters:

```
# restrict == no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty,no-user-rc
restrict,command="echo 'Please login as the user \"debian\" rather than the user \"root\".';echo;sleep 10" ssh-rsa AAAA...
```

### Install a user's SSH key

```bash
u bash -c 'S="${HOME}/.ssh";mkdir --mode 0700 "$S";editor "${S}/authorized_keys"'
U="$(stat -c %U .)";S="$(getent passwd $U|cut -d: -f6)/.ssh";mkdir -m 0700 "$S";editor "${S}/authorized_keys";chown -R $U:$U "$S"
```

### Retrieve public key from private key

```bash
ssh-keygen -y -f ~/.ssh/id_ecdsa
```

### List sshd host keys

```bash
ls /etc/ssh/ssh_host_*_key.pub | xargs -n 1 ssh-keygen -l -f
```

### Record terminal session

```bash
script --timing=NAME.time --append NAME.script
scriptreplay --maxdelay 1 NAME.time NAME.script
```

### Fast and safe transit of scripts (or any data) via copy&paste

##### Pack

```bash
cat $SCRIPT|xz -9|base64 -w $((COLUMNS-1))
# alias: cat $SCRIPT | transit
```

##### Unpack

```bash
cat $PASTED_FILE|base64 -d|xz -d > $SCRIPT
# alias: cat $PASTED_FILE | transit-receive
```

### Moving away git-dir

```bash
git init --separate-git-dir=/home/user/gitdir
```

Produces:

/home/user/work-dir/.git: `gitdir: /home/user/git`

/home/user/gitdir/config: `worktree = /home/user/work-dir`

### Rescan the SCSI Bus to Add SCSI Devices

```bash
echo "- - -" > /sys/class/scsi_host/host0/scan
```

### Flush Google public DNS cache

https://google-public-dns.appspot.com/cache

### Free CDN for GitHub

https://rawgit.com/ `https://cdn.rawgit.com/USER/REPO/TAG/FILE`

### ROA validation, RPKI status

`whois -h whois.bgpmon.net 84.2.228.0`

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

### Looking for maintenance for your application or website?

Contact me: viktor@szepe.net
