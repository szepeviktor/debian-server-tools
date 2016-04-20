# IPtables rules

### Log outgoing SMTP traffic of website (non-MTA) users

```bash
echo USER1 USER2 USER3 | xargs -n 1 -I %% iptables -I OUTPUT \
    -o eth0 \
    -m state --state NEW \
    -p tcp -m multiport --dports 25,465,587 \
    -m owner --uid-owner %% \
    -j LOG --log-prefix "SMTP web: " --log-level 4 --log-uid
iptables -nvL OUTPUT
```

Against spamming.
@FIXME Except transactional email providers
