### Sign a certificate

```bash
cd /root/ssl/szepe.net-ca/
export SSLEAY_CONFIG="-config /root/ssl/szepe.net-ca/config/openssl.cnf"
./CAszepenet.sh -newreq
./CAszepenet.sh -sign
# CA-PASSWORD

C=$(dirname $(pwd))/$(date +%Y%m%d)-HOSTNAME
mkdir -v ${C}
openssl rsa -in ./newkey.pem -out ${C}/priv-key-$(date +%Y%m%d).key
mv -v ./newkey.pem ${C}/priv-key-$(date +%Y%m%d)-encrypted.key
sed -n '/-----BEGIN CERTIFICATE-----/,$p' ./newcert.pem > ${C}/pub-key-$(date +%Y%m%d).pem
rm -v newcert.pem newreq.pem
```

### Install CA

```bash
CA_NAME="szepenet"
CA_FILE="szepenet_ca.crt"
CA_URL="http://ca.szepe.net/szepenet-ca.pem"
#    CA_NAME="PositiveSSL2"
#    CA_FILE="PositiveSSL_CA_2.crt"
#    CA_URL="https://support.comodo.com/index.php?/Knowledgebase/Article/GetAttachment/943/30"

mkdir -v /usr/local/share/ca-certificates/${CA_NAME}
wget -O /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE} ${CA_URL}
# Use local copy
#     cp ${D}/security/ca/ca-web/szepenet-ca.pem /usr/local/share/ca-certificates/${CA_NAME}/${CA_FILE}
update-ca-certificates -v -f
```
