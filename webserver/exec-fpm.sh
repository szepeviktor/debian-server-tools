#!/bin/sh
#
# Execute a PHP script in FPM SAPI.
#
# VERSION       :0.1.0
# DATE          :2019-05-20
# URL           :https://github.com/szepeviktor/debian-server-tools
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# REFS          :https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/
# DOCS          :http://www.gregfreeman.io/2016/how-to-connect-to-php-fpm-directly-to-resolve-issues-with-blank-pages/
# DEPENDS       :apt-get install libfcgi-bin

# EDIT here
FPM_USER="site1"
FPM_SOCKET="/run/php/php7.2-fpm-${FPM_USER}.sock"
SCRIPT="/home/${FPM_USER}/website/code/fpm.php"

sudo -u "$FPM_USER" \
    SCRIPT_FILENAME="$SCRIPT" REQUEST_METHOD="GET" REQUEST_URI="/" QUERY_STRING="" \
    cgi-fcgi -bind -connect "$FPM_SOCKET"
