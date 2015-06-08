### Sign a certificate

```bash
cd /root/ssl/szepe.net-ca/
export SSLEAY_CONFIG="-config /root/ssl/szepe.net-ca/config/openssl.cnf"
./CAszepenet.sh -newreq
./CAszepenet.sh -sign
# CA-PASSWORD

C=$(dirname $(pwd))/$(date +%Y%m%d)-HOSTNAME
mkdir $C
openssl rsa -in ./newkey.pem -out $C/priv-key-$(date +%Y%m%d).key
mv ./newkey.pem $C/priv-key-$(date +%Y%m%d)-encrypted.key
sed -n '/-----BEGIN CERTIFICATE-----/,$p' ./newcert.pem > $C/pub-key-$(date +%Y%m%d).pem
rm newcert.pem newreq.pem
```

### Install a CA

```bash
mkdir /usr/local/share/ca-certificates/<CA-NAME>
#wget -O PositiveSSL_CA_2.crt https://support.comodo.com/index.php?/Knowledgebase/Article/GetAttachment/943/30
#wget -O szepenet_ca.crt http://ca.szepe.net/ca
#cp $D/security/ca/szepenet-ca.crt /usr/local/share/ca-certificates/<CA-NAME>/
#cp <CA-FILE>.crt /usr/local/share/ca-certificates/<CA-NAME>/
update-ca-certificates -v -f
```
