# Debian server tools

You find all my knowledge on GitHub in form of Bash and PHP scripts and Markdown documents.  
Updated daily as I work.

### Featured documents :star:

1. [Too much of a website](/webserver/Production-website.md)
1. [Web application development](/webserver/PHP-development.md)
1. [Setting up your infrastructure and your application](/Onboarding.md)
1. [All things WordPress](/webserver/WordPress.md)
1. [WordPress Security](/webserver/WordPress-security.md)
1. [Running Laravel](/webserver/laravel)
1. [Running Drupal](/webserver/Drupal.md)
1. [Monitoring on paranoid level](/monitoring#readme)
1. [Continuous Integration and Continuous Delivery](/webserver/Continuous-integration-Continuous-delivery.md)
1. [Debian setup on UpCloud server](/debian-setup)
   including [Resize root filesystem during boot](/debian-setup/debian-resizefs.sh)
1. [Live list of Hostile networks](/security/myattackers-ipsets/ipset)
1. [Bulk mail sending](/mail/README.md#bulk-mail)

### Magyar nyelvű kiemelet dokumentumok :hungary:

1. [Csapatának tagja szeretnék lenni](/CV2.md)
1. [Ismerkedés Új ügyfelekkel](/Onboarding-business.md)
1. [Teljesítménycentrikus webhely tervezése](/webserver/Website-Funnel-UX.md)
1. [Honlap jogi dolgai + GDPR](/webserver/Production-website.md#jogi-dolgok-hu)
1. [Kézi Tesztelési Kézikönyv](/webserver/Manual-testing.md)
1. [Képek életciklusa](/image/Kep-eletciklus.md)
1. [Magyar email szolgáltatók](/mail/Hungarian-ESP.md)
1. [`(direct) / (none)` Google Analytics-ben](/monitoring/Analytics-direct-none-traffic.md)
1. [Google Analytics URL készítő](/webserver/analytics-url-builder)

### Superior cloud hosting

Install Debian on [**UpCloud**](https://www.upcloud.com/register/?promo=U29Q8S)

How UpCloud was chosen? Read https://github.com/szepeviktor/wordpress-speedtest/blob/master/README.md#how-to-choose-vps-provider

### Ergonomics

[How to Set Up Your Desk](https://youtu.be/F8_ME4VwTiw?t=31)

### Model of how systems work

[Richard Cook at Velocity NY 2013](https://youtu.be/PGLYEDpNu60?t=5m44s)

### Directories

- /debian-setup - Debian installation scripts including [debian-setup.sh](/debian-setup/debian-setup.sh)
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

### Debian install with UTC as timezone

Select Expert install.

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

### Display SSH access details

```bash
printf 'host: %s\nport: %s\nuser: %s\n' "$(hostname)" "$(/usr/sbin/sshd -T -C user=root|sed -ne 's/^port \([0-9]\+\)$/\1/p')" "$(ls -tr /home/|tail -n1)"
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

Use [magic-wormhole](https://github.com/warner/magic-wormhole)

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

https://staticaly.com/ `https://cdn.staticaly.com/gh/USER/REPO/TAG/FILE`

### Whois servers

- `whois -h whois.iana.org $TLD` https://www.iana.org/domains/root/db
- `dig _nicname._tcp.$TLD SRV` https://tools.ietf.org/html/draft-sanz-whois-srv-01
- https://github.com/rfc1036/whois/blob/next/tld_serv_list

### AS information

`whois -h whois.radb.net -- "-i origin AS202053"`

### ROA validation, RPKI status

`whois -h whois.bgpmon.net 94.237.81.0`

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

### Cron scheduling with timezone

```cron
# Well before the actual execution time!
00 06  * * *  echo "/bin/ls -l" | at "$(date --date='TZ="Europe/Budapest" 10:30' "+\%H:\%M")" 2>/dev/null
```

### Looking for a dedicated team member running your application or website?

Contact me: viktor@szepe.net
