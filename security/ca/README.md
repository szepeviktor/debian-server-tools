# Custom certificates

### Sign a certificate

```bash
cd /root/ssl/szepe.net-ca/
export SSLEAY_CONFIG="-config /root/ssl/szepe.net-ca/config/openssl.cnf"
./CAszepenet.sh -newreq
./CAszepenet.sh -sign
# Enter CA-PASSWORD

C=$(dirname $(pwd))/$(date +%Y%m%d)-$(openssl x509 -in newcert.pem -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')
C="${C/\*/wildcard}"
mkdir -v ${C}
openssl rsa -in ./newkey.pem -out ${C}/priv-key-$(date +%Y%m%d).key
sed -ne '/-----BEGIN CERTIFICATE-----/,$p' ./newcert.pem > ${C}/pub-key-$(date +%Y%m%d).pem
rm -v newcert.pem newreq.pem && ls -l ${C}
```

### Renew a certificate

```bash
cd /root/ssl/szepe.net-ca/
export SSLEAY_CONFIG="-config /root/ssl/szepe.net-ca/config/openssl.cnf"
read -r -e -p "Old cert=" -i "../20991231-common.name/pub-key-20991231.pem" OLDC
openssl ca -revoke $OLDC
C=$(dirname $(pwd))/$(date +%Y%m%d)-$(openssl x509 -in $OLDC -noout -subject|sed -ne 's;^.*/CN=\([^/]\+\).*$;\1;p')
OLDKEY=${OLDC/pub-key-/priv-key-}
openssl x509 -x509toreq -in $OLDC -signkey ${OLDKEY/.pem/.key} > newreq.pem
./CAszepenet.sh -sign
# Enter CA-PASSWORD
mkdir -v ${C}
sed -ne '/-----BEGIN CERTIFICATE-----/,$p' ./newcert.pem > ${C}/pub-key-$(date +%Y%m%d).pem
cp -v $OLDC ${C}/priv-key-$(date +%Y%m%d).key
rm -v newcert.pem newreq.pem && ls -l ${C}
```

### Export PKCS#12 client certificate

```bash
openssl pkcs12 -export -in newcert.pem -inkey newkey-decrypted.pem -out email@addre.ss-szepenet.p12 -name friendlyname
```

### Install a CA

```bash
CA_NAME="szepenet"
# Must have "crt" extension
CA_FILE="szepenet_ca.crt"
CA_URL="http://ca.szepe.net/szepenet-ca.pem"

#    CA_NAME="PositiveSSL2"
#    CA_FILE="PositiveSSL_CA_2.crt"
#    CA_URL="https://support.comodo.com/index.php?/Knowledgebase/Article/GetAttachment/943/30"

mkdir -v /usr/local/share/ca-certificates/${CA_NAME}
wget -O /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE} ${CA_URL}
# Use local copy
#     cp -v ${D}/security/ca/ca-web/szepenet-ca.pem /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE}
update-ca-certificates -v -f
openssl x509 -noout -modulus -in /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE} | openssl sha256 \
    | grep --color "769d14e4068b1eb76bf753bdb04d36ec9e0f7237229f30566af82eae76ecdb4d"
```
