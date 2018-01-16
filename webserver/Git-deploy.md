## The main advantages of using git for deployment

- Being able to deploy from your desktop.
- Easy rollback to a previous version.
- Able to setup deployment to staging/production environments.

## Path of repositories on a Debian-based system

/var/lib/git

### On the server

```bash
DEV_ROOT="<DEVELOPMENT-ROOT>"
LIVE_ROOT="<PRODUCTION-ROOT>"

cat <<EOF > hooks/post-receive
#!/bin/sh

# Go update development website
GIT_WORK_TREE=${DEV_ROOT}/cms git checkout -f
# @TODO Set owner and permissions
rm -rf ${DEV_ROOT}/cms/wp-content
# Symlink live site's /static/uploads directory.
ln -sf ${LIVE_ROOT}/static/uploads ${DEV_ROOT}/static/uploads
EOF

chmod +x hooks/post-receive
```

### In the developer's repo

`~/.ssh/config`

```
Host HOST-ALIAS
  HostName
  Port
  User
  IdentityFile /home/USER/.ssh/id_rsa
  IdentitiesOnly yes
```

```bash
echo "/wp-content/uploads/" >> .gitignore
echo "/videos/" >> .gitignore
```

### WordPress Theme switching

https://github.com/danielbachhuber/git-switch
