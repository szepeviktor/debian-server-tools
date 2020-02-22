# Jira and Confluence installation

### Apache proxy

```apache
    <IfModule mod_proxy_ajp.c>
        ProxyRequests Off
        ProxyVia Block
        ProxyPreserveHost Off
        ProxyPass "/" "ajp://localhost:8009/"
        ProxyPassReverse  "/" "ajp://localhost:8009/"
        <Proxy "ajp://localhost:8009/">
            ProxySet connectiontimeout=5 timeout=65
        </Proxy>
    </IfModule>
```

`a2enmod proxy_ajp`

### Download installer

- `atlassian-jira-software-VERSION-x64.bin` from https://www.atlassian.com/software/jira/update
- `atlassian-confluence-VERSION-x64.bin` from https://www.atlassian.com/software/confluence/download

Show JAVA home.

```bash
grep -v '^#\|^$' /opt/atlassian/jira/atlassian-jira/WEB-INF/classes/jira-application.properties
grep -v '^#\|^$' /opt/atlassian/confluence/confluence/WEB-INF/classes/confluence-init.properties
```

[MySQL Connector/J](https://dev.mysql.com/downloads/connector/j/) *choose "Platform Independent"*

Copy jar file to `/opt/atlassian/*/lib/`

### Dependencies

```bash
apt-get install fontconfig
```

### Set up database

For MySQL configuration see
https://confluence.atlassian.com/adminjiraserver/connecting-jira-applications-to-mysql-5-7-966063305.html

Edit `JIRA-USER` and `PASSWORD`

```bash
mysql --default-character-set=utf8 <<"EOF"
CREATE DATABASE IF NOT EXISTS `jira`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_bin';
GRANT ALL PRIVILEGES ON `jira`.* TO 'JIRA-USER'@'localhost'
    IDENTIFIED BY 'PASSWORD';
FLUSH PRIVILEGES;
EOF

mysql --default-character-set=utf8 <<"EOF"
CREATE DATABASE IF NOT EXISTS `confluence`
    CHARACTER SET 'utf8'
    COLLATE 'utf8_bin';
GRANT ALL PRIVILEGES ON `confluence`.* TO 'CONFLUENCE-USER'@'localhost'
    IDENTIFIED BY 'PASSWORD';
FLUSH PRIVILEGES;
EOF
```

[Confluence MySQL Collation Repair](https://confluence.atlassian.com/confkb/mysql-collation-repair-column-level-changes-670958189.html)

### Import SSL certificate authority

```bash
cd /opt/atlassian/jira/jre/lib/security/
../../bin/keytool -import -alias "CA-ALIAS" -file "CA-FILE.crt" -keystore cacerts
```

Password: `changeit`

### Tomcat

[AJP Connector](https://tomcat.apache.org/tomcat-8.5-doc/config/ajp.html)

```xml
<Server port="8005" shutdown="SHUTDOWN">
    <Service name="Catalina">
        <Connector address="127.0.0.1" port="8009"
            URIEncoding="UTF-8" enableLookups="false" protocol="AJP/1.3"/>
```

[HTTP Connector](https://tomcat.apache.org/tomcat-8.5-doc/config/http.html)

```xml
<Server port="8005" shutdown="SHUTDOWN">
    <Service name="Catalina">
        <Connector address="127.0.0.1" port="8005" maxThreads="150" minSpareThreads="25" connectionTimeout="20000" enableLookups="false"
            maxHttpHeaderSize="8192" protocol="HTTP/1.1" useBodyEncodingForURI="true" redirectPort="8443"
            acceptCount="100" disableUploadTimeout="true" bindOnInit="false" secure="true" scheme="https"
            proxyName="VIRTUALHOST-NAME" proxyPort="443"/>
```

[CSRF protection](https://confluence.atlassian.com/kb/cross-site-request-forgery-csrf-protection-changes-in-atlassian-rest-779294918.html)

### SMTP

Use local MTA at localhost on port 25.

### Init scripts

Add missing run-time dependencies.

```bash
### BEGIN INIT INFO
# Provides:          jira
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Atlassian Jira
# Description:       Atlassian Jira on custom Tomcat
### END INIT INFO
```

```bash
### BEGIN INIT INFO
# Provides:          confluence
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Atlassian Confluence
# Description:       Atlassian Confluence on custom Tomcat
### END INIT INFO
```

Update init script links: `update-rc.d jira defaults`

### Logrotate

/etc/logrotate.d/jira

```logrotate
/opt/atlassian/jira/logs/catalina.out {
    monthly
    missingok
    rotate 6
    compress
    delaycompress
    notifempty
    create 640 jira jira
}
```

/etc/logrotate.d/confluence

```logrotate
/opt/atlassian/confluence/logs/catalina.out {
    monthly
    missingok
    rotate 6
    compress
    delaycompress
    notifempty
    create 640 confluence confluence
}
```

### Backup

- Binaries and configuration path: `/opt/atlassian/`
- Data path: `/var/atlassian/`
    - Custom plugins: `/var/atlassian/application-data/jira/plugins/`
    - Attachments and images: `/var/atlassian/application-data/jira/data/`
    - See `/var/atlassian/application-data/*/dbconfig.xml` for database names

### Upgrade

https://confluence.atlassian.com/adminjiraserver/upgrading-jira-server-manual-938846939.html

- Download installer
- Run installer
- [MariaDB Connector/J](https://mariadb.com/downloads/#connectors)
  from 2.4.0: [disableMariaDbDriver](https://mariadb.com/kb/en/library/about-mariadb-connector-j/#having-mariadb-and-mysql-drivers-in-the-same-classpath)
  and useMysqlMetadata
- Restore server.xml
- User-installed apps: Administration / Manage apps / Manage apps `https://example.com/plugins/servlet/upm`
