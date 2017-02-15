#!/bin/bash
#
# Send newsletter.
#
# VERSION       :0.2.0
# DEPENDS       :apt-get install mpack qprint dos2unix uuid-runtime
# DOCS          :https://ga-dev-tools.appspot.com/campaign-url-builder/
# DOCS          :https://developers.google.com/analytics/devguides/collection/protocol/v1/email

# Usage
#
# 1. Unpack original email:  munpack -t original.eml
# 2. Edit parts, insert utm links and tracker image
# 3. Prepare message skeleton:  cp skel.tpl.eml skeleton.eml
# 4. Set BOUNCE_FROM address and LIST file name here
# 5. Test send using addr-test and https://www.mail-tester.com/
#
# <img src="https://www.google-analytics.com/collect?v=1&amp;
# tid=UA-11111111-1&amp;cid=@@UUID@@&amp;t=event&amp;ec=email&amp;ea=open&amp;cs=newsletter&amp;cm=email&amp;cn=campaign_2017"
# height="1" width="1" alt="" />
#
# <a href="https://example.com/url?
# utm_source=newsletter&amp;utm_campaign=campaign_2017&amp;utm_medium=email&amp;utm_content=toplink">
#
# <a href="mailto:add@re.ss?subject=unsubscribe_Campaign_@@EMAIL40@@">unsubscribe</a>

# @FIXME Non-webmail email clients will have TWO sessions: email client + browser

BOUNCE_FROM="webmaster@example.com"

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
    UUID="$(uuidgen)"

    # Log
    echo "${ADDRESS}	${UUID}	@$(date "+%s")" >> send.log
    # Send
    # shellcheck disable=SC2002
    cat skeleton.eml \
        | sed -e '/@@PART1@@/{r part1.qp' -e ';d}' \
        | sed -e '/@@PART2@@/{r part2.qp' -e ';d}' \
        | sed -e "s|@@EMAIL@@|${ADDRESS}|g" \
        | sed -e "s|@@EMAIL40@@|${ADDRESS/@/%40}|g" \
        | sed -e "s|@@UUID@@|${UUID}|g" \
        | /usr/sbin/sendmail -f "$BOUNCE_FROM" "$ADDRESS"
    RET="$?"

    if [ "$RET" != 0 ]; then
        echo -ne " ... ${RET}\x07 ------------------"
    fi
    echo

    # Wait 0 or 1 second
    sleep "$((RANDOM % 2))"
done < "$LIST"
