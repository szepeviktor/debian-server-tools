#!/bin/bash --version

exit 0

dpkg -i trafficserver_6.1.1-1_amd64.deb

echo "src_ip=${CLIENT_IP}  action=ip_allow method=ALL" >> /etc/trafficserver/ip_allow.config

SSL_DIR="/etc/trafficserver/ssl"
install -o root -g trafficserver -m 750 -d "${SSL_DIR}"
openssl genrsa -out "${SSL_DIR}/ts-fwdproxy.key" 2048
openssl req -new -key "${SSL_DIR}/ts-fwdproxy.key" -out "${SSL_DIR}/ts-fwdproxy.csr"
# Common Name []: ${SERVER_IP}
openssl x509 -req -days 365 -in "${SSL_DIR}/ts-fwdproxy.csr" -signkey "${SSL_DIR}/ts-fwdproxy.key" -out "${SSL_DIR}/ts-fwdproxy-cert.pem"
echo "ssl_cert_name=${SSL_DIR}/ts-fwdproxy-cert.pem ssl_key_name=${SSL_DIR}/ts-fwdproxy.key" >> /etc/trafficserver/ssl_multicert.config

traffic_line -s proxy.config.url_remap.remap_required -v 0
traffic_line -s proxy.config.http.cache.http -v 1
traffic_line -s proxy.config.reverse_proxy.enabled -v 0
traffic_line -s proxy.config.http.server_ports -v 8080:ssl
traffic_line -s proxy.config.ssl.client.CA.cert.path -v "/etc/ssl/certs/"
traffic_line -s proxy.config.ssl.server.cert.path -v "${SSL_DIR}/ts-fwdproxy-cert.pem"
traffic_line -s proxy.config.ssl.server.private_key.path -v "${SSL_DIR}/ts-fwdproxy.key"
##traffic_line -s proxy.config.ssl.ocsp.enabled -v 1
#traffic_line -s proxy.config.ssl.TLSv1 -v 0
#traffic_line -s proxy.config.ssl.TLSv1_1 -v 0
#traffic_line -s proxy.config.ssl.server.cipher_suite -v ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256

clear; traffic_line --restart_local; tail -n0 -f /var/log/trafficserver/*.log

# PROXY.PAC
#     function FindProxyForURL(url, host) { return "HTTPS ${SERVER_IP}:8080"; }
