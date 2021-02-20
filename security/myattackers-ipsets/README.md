# Hostile networks

### Classifying Attackers

- 25% are [known hostile networks](ipset) (nothing good comes from them)
- 25% are bots
- 25% come from known cloud providers
- 25% are "researchers"

Source: https://www.hackerfactor.com/blog/index.php?/archives/775-Scans-and-Attacks.html

Bot Directory by Distil Networks (now part of Impreva): https://www.distilnetworks.com/bot-directory/

Udger's crawler list: https://udger.com/resources/ua-list/crawlers

Similar list of hostile networks: https://gitlab.com/ohisee/block-shodan-stretchoid-census

### Usage

Run `myattackers-ipsets-install.sh`

Update ipset files with embedded update script: `sed -n -e 's/^#\$ //p' example.ipset | bash`

### Usage on systems without ipset

```bash
grep -h '^add' *.ipset | cut -d " " -f 3 | sortip \
    | sed -e 's#^[0-9.]\+$#&/32#' \
    | xargs -L 1 -- echo "iptables -I myattackers -j REJECT -s"
```

### Usage in htaccess files

```bash
echo "<RequireAll>"
echo "Require all granted"
grep -h '^add' *.ipset | cut -d " " -f 3 | sortip \
    | xargs -L 1 -- echo "Require not ip"
echo "</RequireAll>"
```

### Usage on Mikrotik routers

```bash
grep -h '^add' *.ipset | cut -d " " -f 3 | sortip \
    | xargs -I % -- echo "/ip firewall address-list add list=myattackers-ipset address=%" \
    >mikrotik-myattackers-ipset.rsc
```

Execution on the router: `/import file=mikrotik-myattackers-ipset.rsc`
