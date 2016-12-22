#!/bin/bash
#
# Send newsletter.
#
# VERSION       :0.1.1
# DEPENDS       :apt-get install mpack qprint dos2unix uuid-runtime
# DOCS          :https://ga-dev-tools.appspot.com/campaign-url-builder/
# DOCS          :https://developers.google.com/analytics/devguides/collection/protocol/v1/email

# Usage
#
# 1. Unpack original email:  munpack -t original.eml
# 2. Edit parts, insert utm links and tracker image
# 3. Prepare message skeleton:  cp skel.tpl.eml skeleton.eml
# 4. Set FROM address and LIST file name here
# 5. Test send using addr-test
#
# <img src="https://www.google-analytics.com/collect?v=1&
# tid=UA-11111111-1&cid=@@UUID@@&t=event&ec=email&ea=open&cs=newsletter&cm=email&cn=2016_campaign"
# height="1" width="1" alt="" />
#
# <a href="https://example.com/es/gift?
# utm_source=newsletter&utm_campaign=2016_campaign&utm_medium=email">
#
# <a href="mailto:add@re.ss?subject=unsubscribe_Campaign_@@EMAIL@@ -> url encode, @ -> %40">unsubscribe</a>

FROM="webmaster@example.com"

#LIST="addr"
LIST="addr-test"

[ -f "$LIST" ] || exit 1
[ -f part1 ] || exit 1
[ -f part2 ] || exit 1

declare -i COUNT="0"

# Encode parts
sed -i -e 's|\s\s\+| |g' -e 's|^\s||' part1
qprint -e part1 | sed 's|\t|=09|g' > part1.qp
dos2unix -q part1.qp

sed -i -e 's|\s\s\+| |g' -e 's|^\s||' part2
qprint -e part2 | sed 's|\t|=09|g' > part2.qp
dos2unix -q part2.qp

while read -r ADDRESS; do
    echo -n "$((++COUNT)). ${ADDRESS}"

    # Send
    # shellcheck disable=SC2002
    cat skeleton.eml \
        | sed -e '/@@PART1@@/{r part1.qp' -e ';d}' \
        | sed -e '/@@PART2@@/{r part2.qp' -e ';d}' \
        | sed -e "s|@@EMAIL@@|${ADDRESS}|g" \
        | sed -e "s|@@UUID@@|$(uuidgen)|g" \
        | /usr/sbin/sendmail -f "$FROM" "$ADDRESS"
    RET="$?"

    if [ "$RET" != 0 ]; then
        echo -ne " ... ${RET}\x07 ------------------"
    fi
    echo

    # Wait 0 or 1 second
    sleep "$((RANDOM % 2))"
done < "$LIST"
