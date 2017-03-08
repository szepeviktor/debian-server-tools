# Bash shell types

1. Invoked as an interactive login shell (`$0` is `-bash`)
1. Invoked as an interactive non-login shell
1. Invoked non-interactively

https://www.gnu.org/software/bash/manual/bash.html#Invoking-Bash

| Command                  | Shell type      | Executed files                 |
| ------------------------ | --------------- | ------------------------------ |
| Console login            | login           | /etc/profile /etc/bash.bashrc /root/.profile /root/.bashrc |
| SSH login                | login           | /etc/profile /etc/bash.bashrc /root/.profile /root/.bashrc |
| `ssh -- bash -c command` | non-interactive | /etc/bash.bashrc /root/.bashrc |
| `sudo -u user -- bash`   | non-login       | /etc/bash.bashrc $HOME/.bashrc |
| `mc`                     | non-login       | /etc/bash.bashrc /root/.bashrc |
| `screen`                 | non-login       | /etc/bash.bashrc /root/.bashrc |
| `bash` (subshell)        | non-login       | /etc/bash.bashrc /root/.bashrc |
| `bash -c command` (subshell) | non-login   |                                |
| `sh` (subshell)          | non-login       |                                |
| Cron job                 | non-interactive |                                |

https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files

```bash
shopt -q login_shell && echo "It is a login shell."

[[ $- == *i* ]] && echo "Interactive shell"
```
