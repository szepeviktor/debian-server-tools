# IPtables rules

### Restrict outgoing SMTP traffic

Against spamming.

```bash
iptables -D OUTPUT \
    -o eth0 \
    -p tcp -m multiport --dports 25,465,587 \
    -j out-smtp || true
iptables -F out-smtp || true
iptables -X out-smtp || true

iptables -N out-smtp
iptables -A out-smtp \
    -m owner --uid-owner daemon \
    -j ACCEPT
#iptables -A out-smtp \
#    -dport 587
#    -m owner --uid-owner $WEB_USER_WITH_SMTP \
#    -j ACCEPT
iptables -A out-smtp \
    -m state --state NEW \
    -j LOG --log-prefix "SMTP illegal: " --log-level 4 --log-uid
iptables -A out-smtp \
    -j REJECT
iptables -I OUTPUT \
    -o eth0 \
    -p tcp -m multiport --dports 25,465,587 \
    -j out-smtp

iptables -nvL OUTPUT; iptables -nvL out-smtp
```
