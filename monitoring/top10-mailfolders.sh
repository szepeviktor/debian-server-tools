#!/bin/bash
#
# Report TOP 10 mail folders by message cound and by size.
#
# VERSION       :0.2.1
# DATE          :2015-10-16
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install heirloom-mailx
# LOCATION      :/usr/local/sbin/top10-mailfolders.sh
# CRON-MONTHLY  :/usr/local/sbin/top10-mailfolders.sh

# This script expects the following mail structure:
#
# /var/mail/DOMAIN/USER/Maildir

MAILROOT="/var/mail"

Exec_on_folders() {
    find "$MAILROOT" -type d -name "cur" -exec bash -c "$1" ";"
}

Top_579() {
    #          -f user,folder,size
    cut -d "/" -f 5,7,9 \
    | sort -t "/" -n -r -k 3 \
    | head \
    | sed "s;/;\t/ ;g"
}

{
    echo -e "TOP 10 mail folders by message count\n"
    Exec_on_folders "echo -n '{}/'; ls -f '{}' | wc -l" \
        | Top_579

    echo -e "\n---------------\n"

    echo -e "TOP 10 mail folders by size\n"
    Exec_on_folders "echo -n '{}/'; du -s --block-size=M '{}' | cut -f 1" \
        | Top_579

    echo -e "\n---------------\n"

    echo -e "All mail folders\n"
    du -s --block-size=G "$MAILROOT"

} | mailx -S from="top 10 mail folders <root>" -s "[admin] TOP 10 mail folders on $(hostname -f)" root

exit 0
