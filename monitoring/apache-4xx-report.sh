#!/bin/bash
#
# Report Apache client and server errors of the last 24 hours.
#
# VERSION       :3.0.0
# DATE          :2023-03-18
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# URL           :https://github.com/szepeviktor/debian-server-tools
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install mail-transport-agent apache2 ccze perl dategrep
# LOCATION      :/usr/local/sbin/apache-4xx-report.sh
# CRON-DAILY    :/usr/local/sbin/apache-4xx-report.sh

CCZE_CSS_URL="https://cdn.rawgit.com/szepeviktor/debian-server-tools/master/monitoring/apache-ccze.css"
CCZE_BODY_BG="#fdf6e3"
EMAIL_HEADER="Subject: [admin] HTTP client errors from $(hostname -f)
From: webserver <root>
To: admin@szepe.net
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
"
APACHE_CONFIGS="$(find /etc/apache2/sites-enabled/ -type l -name "*.conf")"

# 1.2.3.4 - - [27/Jun/2015:14:35:41 +0200] "GET /request-uri HTTP/1.1" 404 1234 "-" "User-agent/1.1"
declare -a IGNORE_PATTERNS=(
    # 408 Request Timeout on preconnect
    '"-" 408 [0-9]+ "-" "-(\|Host:-)?"$'
    # Bad request
    '"GET / HTTP/(1\.0|1\.1|2\.0)" 400 0 "-" "-"$'
    # Tunneling through Amazon CloudFront for blocked news sites in China
    '"GET /(ogShow\.aspx|show\.aspx|ogPipe\.aspx|oo\.aspx|1|email|img/logo-s\.gif) HTTP/(1\.0|1\.1|2\.0)" (301|403) [0-9]+ "[^"]+" "Amazon CloudFront"$'
    # Favicon in subdirectory
    #'/favicon\.(ico|png) HTTP/(1\.0|1\.1|2\.0)" (403|404) [0-9]+ "'
    # WordPress login page
    #'"GET /wp-login\.php HTTP/(1\.0|1\.1|2\.0)" 404'
    #'"GET /wp-login\.php HTTP/(1\.0|1\.1|2\.0)" 403'
    #'"GET /wp-login\.php\?redirect_to=\S+ HTTP/(1\.0|1\.1|2\.0)" 404'
    #'"GET /wp-login\.php\?redirect_to=\S+ HTTP/(1\.0|1\.1|2\.0)" 403'
    #'"GET /[a-z]+/wp-login\.php HTTP/(1\.0|1\.1|2\.0)" 404'
    #'"GET /[a-z]+/wp-login\.php HTTP/(1\.0|1\.1|2\.0)" 403'
    #'"GET /[a-z]+/wp-login\.php\?redirect_to=\S+ HTTP/(1\.0|1\.1|2\.0)" 404'
    #'"GET /[a-z]+/wp-login\.php\?redirect_to=\S+ HTTP/(1\.0|1\.1|2\.0)" 403'
    # WordPress' Windows Live Writer manifest
    #'/wlwmanifest\.xml HTTP/(1\.0|1\.1|2\.0)" (403|404) [0-9]+ "'
    # WordPress direct execution
    #'"GET /wp-content/(plugins|themes)/\S+(\.php(\?\S+)?|/readme\.txt) HTTP/(1\.0|1\.1|2\.0)" 403'
    # Dynamic request from AWS CDN
    #'"GET /\S* HTTP/(1\.0|1\.1|2\.0)" 403 [0-9]+ "-" "Amazon CloudFront"$'
    # cPanel's Let's Encrypt HTTP-01 challenge
    #'"GET /\.well-known/acme-challenge/.* "-" "Cpanel-HTTP-Client/1\.0"$'
    # SEO bots
    #'"GET /.* HTTP/(1\.0|1\.1|2\.0)" 404 [0-9]+ "[^"]+" "[^"]*(SemrushBot/|DotBot/|AhrefsBot/|MJ12bot/|AlphaBot/|BLEXBot/)[^"]*"$'
    # Google crawler https://en.wikipedia.org/wiki/List_of_search_engines#General
    #'"GET /.* HTTP/(1\.0|1\.1|2\.0)" 404 [0-9]+ "[^"]+" "[^"]*(Googlebot/2\.1|Googlebot-Image/1\.0|Google Web Preview)[^"]*"$'
    # Other search engine crawlers
    #'"GET /.* HTTP/(1\.0|1\.1|2\.0)" 404 [0-9]+ "[^"]+" "[^"]*(Baiduspider/2\.0|bingbot/2\.0|DuckDuckBot/1\.1|PetalBot;|YandexBot/3\.0|Qwantify/2\.4w)[^"]*"$'
    # Feed fetchers
    #'"GET /.* HTTP/(1\.0|1\.1|2\.0)" 404 [0-9]+ "[^"]+" "[^"]*(facebookexternalhit/|Twitterbot/|Mail\.RU_Bot/Img/)[^"]*"$'
    # DNS over HTTP
    #'"GET /dns-query\?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB HTTP/(1\.0|1\.1|2\.0)"'
)

Color_html()
{
    ccze --plugin httpd --html --options "cssfile=${CCZE_CSS_URL}" --color "cssbody=${CCZE_BODY_BG}" \
        | perl -MMIME::QuotedPrint -p -e '$_=MIME::QuotedPrint::encode_qp($_);'
}

Maybe_sendmail()
{
    local STRIPPED_BYTE

    read -r -n 1 STRIPPED_BYTE \
        && {
            # stdin is not empty
            echo "${EMAIL_HEADER}"
            { echo -n "${STRIPPED_BYTE}"; cat; } | Color_html
        } | /usr/sbin/sendmail
}

In_array()
{
    local NEEDLE="$1"
    local ELEMENT

    shift

    for ELEMENT; do
        if [ "${ELEMENT}" == "${NEEDLE}" ]; then
            return 0
        fi
    done

    return 1
}

Array_to_lines()
{
    while [ -n "${1}" ]; do
        echo "${1}"
        shift
    done
}

declare -a PROCESSED_LOGS

if [ -z "${APACHE_CONFIGS}" ]; then
    echo "Apace log files could not be found." 1>&2
    exit 1
fi

# APACHE_LOG_DIR is defined here
# shellcheck disable=SC1091
source /etc/apache2/envvars

# For non-existent previous log files
shopt -s nullglob

LOG_EXCERPT="$(mktemp --suffix=.apachelog)"

while read -r CONFIG_FILE; do
    # Skip if marked
    if grep --quiet --fixed-strings '#APACHE-4XXREPORT-SKIP#' "${CONFIG_FILE}"; then
        continue
    fi

    ACCESS_LOG="$(sed -n -e '/^\s*CustomLog\s\+\(\S\+\)\s\+\S\+.*$/I{s//\1/p;q;}' "${CONFIG_FILE}")"
    SITE_USER="$(sed -n -e '/^\s*Define\s\+SITE_USER\s\+\(\S\+\).*$/I{s//\1/p;q;}' "${CONFIG_FILE}")"
    # Substitute variables
    ACCESS_LOG="$(sed -e "s#\${APACHE_LOG_DIR}#${APACHE_LOG_DIR}#g" -e "s#\${SITE_USER}#${SITE_USER}#g" <<<"${ACCESS_LOG}")"

    # Prevent double log processing
    if In_array "${ACCESS_LOG}" "${PROCESSED_LOGS[@]}"; then
        continue
    fi
    PROCESSED_LOGS+=( "${ACCESS_LOG}" )

    # Log lines for 1 day from Debian cron.daily
    # https://datatracker.ietf.org/doc/html/rfc9110#section-15.5
    nice dategrep --multiline \
        --start "now truncate 24h add -17h35m" --end "06:25:00" "${ACCESS_LOG}".[1] "${ACCESS_LOG}" \
        | grep --extended-regexp '" (40[0-9]|41[0-7]|42[126]|50[0-5]) [0-9]+ "' \
        | sed -e "s#^#$(basename "${ACCESS_LOG}" .log): #"

    ## "+" encoded spaces, lower case hexadecimal digits
    #nice dategrep --multiline \
    #    --start "now truncate 24h add -17h35m" --end "06:25:00" "${ACCESS_LOG}".[1] "${ACCESS_LOG}" \
    #    | grep --extended-regexp '([?&][^= ]+=[^& ]*\+|\?\S*%[[:xdigit:]]?[a-f])' \
    #    | sed -e "s#^#$(basename "${ACCESS_LOG}" .log): #"
done <<<"${APACHE_CONFIGS}" >"${LOG_EXCERPT}"

{
    echo "$(wc -l <"${LOG_EXCERPT}") errors total."

    for PATTERN in "${IGNORE_PATTERNS[@]}"; do
        COUNT="$(grep --extended-regexp --count "${PATTERN}" "${LOG_EXCERPT}")"
        if [ "${COUNT}" == 0 ]; then
            continue
        fi
        echo "Ignored: $(printf '%4d' "${COUNT}") × #${PATTERN}#"
    done

    Array_to_lines "${IGNORE_PATTERNS[@]}" \
        | grep --extended-regexp --invert-match --file=- "${LOG_EXCERPT}" \
        | dd iflag=fullblock bs=1M count=5 2>/dev/null
} | Maybe_sendmail

rm "${LOG_EXCERPT}"

# Report PHP-FPM errors
nice dategrep --multiline \
    --start "now truncate 24h add -17h35m" --end "06:25:00" /var/log/php*-fpm.log.[1] /var/log/php*-fpm.log \
    | grep --fixed-strings --invert-match ' NOTICE: ' \
    | sed -e 's#^#php-fpm.log: #' \
    | Maybe_sendmail

exit 0
