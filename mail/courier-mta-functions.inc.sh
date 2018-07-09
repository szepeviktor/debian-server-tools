# shellcheck shell=bash
# Common functions for courier-mta-*.sh

Courier_pythonfilter_pyhton2()
{
    # Courier pythonfilter (Python 2)
    #     Original URL: http://www.dragonsdawn.net/~gordon/courier-pythonfilter/
    #     Python package: https://pypi.python.org/pypi/courier-pythonfilter
    #     Source: https://bitbucket.org/gordonmessmer/courier-pythonfilter
    #     Installation path: /usr/local/lib/python2.7/dist-packages/pythonfilter
    apt-get install -y libpython2.7-dev libxml2-dev libxslt1-dev cython python-gdbm
    pip2 -v install py2-ipaddress lxml html2text
    pip2 -v install "https://bitbucket.org/gordonmessmer/courier-pythonfilter/get/default.tar.gz"

    # Data directory
    # shellcheck disable=SC1091
    MAILUSER="$(source /etc/courier/esmtpd > /dev/null; echo "$MAILUSER")"
    # shellcheck disable=SC1091
    MAILGROUP="$(source /etc/courier/esmtpd > /dev/null; echo "$MAILGROUP")"
    install -v --owner="$MAILUSER" --group="$MAILGROUP" -d /var/lib/pythonfilter

    # Download custom modules
    for MODULE in log_mailfrom_rcptto spamassassin3 email-correct; do
        wget -P "/usr/local/lib/python2.7/dist-packages/pythonfilter/" \
            "https://github.com/szepeviktor/courier-pythonfilter-custom/raw/master/${MODULE}.py"
    done
    # Enable modules in order
    cat >> /etc/pythonfilter.conf <<"EOT"

log_mailfrom_rcptto
#attachments
#noreceivedheaders
noduplicates
#clamav
whitelist_auth
whitelist_relayclients
whitelist_block
spamassassin3
email-correct
EOT

    #editor /etc/pythonfilter-modules.conf

    # Activation
    ln -s -v /usr/local/bin/pythonfilter /usr/lib/courier/filters/pythonfilter
    /usr/sbin/filterctl start pythonfilter
    # Verify activation
    readlink -v /etc/courier/filters/active/pythonfilter
}

Courier_pythonfilter()
{
    # Courier pythonfilter (Python 3)
}

Z_dkim_filter()
{
    # zdkimfilter
    # https://www.tana.it/sw/zdkimfilter/

    DKIM_DOMAIN="$1"
    test -z "$DKIM_DOMAIN" && return 100

    apt-get install -y dbconfig-no-thanks opendkim-tools zdkimfilter

    # Data directory
    # shellcheck disable=SC1091
    MAILUSER="$(source /etc/courier/esmtpd > /dev/null; echo "$MAILUSER")"
    # @FIXME Who should be the owner?
    install    -v --owner=root        --group=root -m 700 -d /etc/courier/filters/privs
    ## install -v --owner="$MAILUSER" --group=root -m 700 -d /etc/courier/filters/privs
    mkdir -v /etc/courier/filters/keys

    # Configuration file
    cp -v /usr/share/zdkimfilter/zdkimfilter.conf.orig.dist /etc/courier/filters/zdkimfilter.conf
    cat >> /etc/courier/filters/zdkimfilter.conf <<EOF

# Domain used if no domain can be derived from the message
default_domain = ${DKIM_DOMAIN}
# Canonicalization for header or body can be simple or relaxed.
header_canon_relaxed = Y
# Add an A-R header to signed outgoing messages
add_auth_pass = Y
# On some errors, e.g. out of memory, return SMTP code 432 to have the sender retry
tempfail_on_error = Y
# Disable new feature for RELAYCLIENT
let_relayclient_alone = Y
# Debug header "z="
#add_ztags = Y
EOF

    # http://www.linuxnetworks.de/doc/index.php/OpenDBX/Configuration#sqlite3_backend
    ##install -b -o --owner="$MAILUSER" --group=root -m 600 /dev/null zdkim.sqlite

    # New key
    DKIM_SELECTOR="dkim$(date --utc "+%Y%m")"
    (
        cd /etc/courier/filters/privs/
        opendkim-genkey -v --domain="$DKIM_DOMAIN" --selector="$DKIM_SELECTOR"
        # Display DKIM record
        echo -n "${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN} IN TXT "
        sed -n -e 's/.*"\([^"]\+\)".*/\1/p' "${DKIM_SELECTOR}.txt" | paste -s -d ""
        echo "host -t TXT ${DKIM_SELECTOR}._domainkey.${DKIM_DOMAIN}."
        # Enable key, use domain names
        chown -c "root:${MAILUSER}" "${DKIM_SELECTOR}.private"
        chmod -c 0640 "${DKIM_SELECTOR}.private"
        # Key name = selector, Symlink name = domain name
        ln -s -v "../privs/${DKIM_SELECTOR}.private" "../keys/${DKIM_DOMAIN}"
    )

    # @FIXME Needs to be the very first filter
    ln -s zdkimfilter /usr/lib/courier/filters/000-zdkimfilter
    # Activation
    /usr/sbin/filterctl start 000-zdkimfilter
    # Verify activation
    readlink /etc/courier/filters/active/000-zdkimfilter
}
