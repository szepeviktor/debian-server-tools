#!/bin/bash
#
# Send newsletter.
#
# VERSION       :0.3.2
# DEPENDS       :apt-get install mpack qprint dos2unix uuid-runtime php7.2-bcmath zdkimfilter at
# DEPENDS-SUDO  :user	ALL=(ALL) NOPASSWD: /usr/bin/dkimsign --filter
# DOCS          :https://ga-dev-tools.appspot.com/campaign-url-builder/
# DOCS          :https://developers.google.com/analytics/devguides/collection/protocol/v1/email
# DOCS          :https://tools.ietf.org/html/rfc2369#section-3.2

# Usage
#
# 1. Remove unsubscribed addresses: maildir, website/unsub.log
# 1. Add new addresses
# 1. Unpack original email:  dos2unix -k original.eml; munpack -t original.eml
# 1. Edit part2: insert utm links into href="..."
# 1. Edit part2: insert tracker image in the footer
# 1. Edit part1: remove HTML entities from links
# 1. Prepare message skeleton:  cp skel.tpl.eml skeleton.eml
# 1. echo "Header to encode" | /usr/local/src/debian-server-tools/mail/conv2047.pl -e
# 1. Set ENVELOPE_FROM address, CAMPAIGN name, LIST file name in this script
# 1. Test send using addr-test
# 1. Check: <title>, href, alt, title, &nbsp; http: (non-https)
# 1. https://mail-tester.com/
# 1. Save part2 as online version: REMOVE online link, unsub link, tracker image, REPLACE @@ placeholders, ADD Analytics snippet
# 1. Schedule:  echo "./newsletter.sh" | at -m 09:00 tomorrow # UTC time
#
# Check HTML table:  grep -Eo '^.*</?(table|tbody|tr|td)(>| ).{0,10}'
#
# <a href="https://example.com/
# ?utm_source=newsletter&amp;utm_medium=email&amp;utm_campaign=@@CAMPAIGN@@&amp;utm_content=button">
#
# <a href="https://example.com/hirlevel/?c=@@CAMPAIGN@@&amp;e=@@EMAIL40@@&amp;h=@@CRYPT@@">unsubscribe</a>
#
# <img src="https://www.google-analytics.com/collect?v=1&amp;
# tid=UA-11111111-1&amp;cid=@@UUID@@&amp;t=event&amp;ec=email&amp;ea=open&amp;cs=newsletter&amp;cm=email&amp;cn=@@CAMPAIGN@@"
# height="1" width="1" alt="" />

ENVELOPE_FROM="user-TAG@example.com"
CAMPAIGN="NL_2017_campaign"

#LIST="addr"
LIST="addr-test"

test -f "$LIST" || exit 1
test -f part1 || exit 1
test -f part2 || exit 1

declare -i COUNT="0"

# Encode parts
sed -i -e 's|\s\s\+| |g' -e 's|^\s||' part1
qprint -e part1 | sed 's|\t|=09|g' >part1.qp
dos2unix -q part1.qp

sed -i -e 's|\s\s\+| |g' -e 's|^\s||' part2
qprint -e part2 | sed 's|\t|=09|g' >part2.qp
dos2unix -q part2.qp

# qprint may brake placeholders onto two lines
if ! cat part1.qp part2.qp | sed -e 's/[^@]//g' \
    | xargs -I% bash -c 'echo -n "%"|wc -c' \
    | grep -qvEx '4|8|12|16|20'; then
    echo "Broken @@placeholders@@" 1>&2
    exit 2
fi

while read -r ADDRESS; do
    echo -n "$((++COUNT)). ${ADDRESS}"
    UUID="$(uuidgen)"
    CRYPT="$(/usr/bin/php7.2 php/hash.php "$ADDRESS")"

    printf '%s\t%s\t@%s\n' "$ADDRESS" "$UUID" "$(date "+%s")" >>send.log

    # Send
    # shellcheck disable=SC2002
    cat skeleton.eml \
        | sed -e '/@@PART1@@/{r part1.qp' -e ';d}' \
        | sed -e '/@@PART2@@/{r part2.qp' -e ';d}' \
        | sed -e "s|@@EMAIL@@|${ADDRESS}|g" \
        | sed -e "s|@@EMAIL40@@|${ADDRESS/@/%40}|g" \
        | sed -e "s|@@UUID@@|${UUID}|g" \
        | sed -e "s|@@CAMPAIGN@@|${CAMPAIGN}|g" \
        | sed -e "s|@@CRYPT@@|${CRYPT}|g" \
        | sudo -- /usr/bin/dkimsign --filter \
        | /usr/sbin/sendmail -f "$ENVELOPE_FROM" "$ADDRESS"
    RET="$?"

    if [ "$RET" != 0 ]; then
        printf ' ... %s\x07 ------------------' "$RET"
    fi
    echo

    # Wait 0 or 1 second
    sleep "$((RANDOM % 2))"
done <"$LIST"
