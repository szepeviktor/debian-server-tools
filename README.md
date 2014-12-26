debian-server-tools
===================

Various scripts and tools for mainly Debian servers

Code styling: https://google-styleguide.googlecode.com/svn/trunk/shell.xml


### /backup

Tools related to archiving.

### /image

Tools related to image optimitazion.

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

### Backup all GitHub repos

```bash
GH_USER="szepeviktor"
wget -qO- "https://api.github.com/users/${GH_USER}/repos?per_page=100"|grep '"clone_url"'|cut -d'"' -f4 > github.repos
cat github.repos|xargs -L 1 git clone
```
