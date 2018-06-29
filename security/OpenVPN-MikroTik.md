# Setting up OpenVPN in a MikroTik router

- https://wiki.mikrotik.com/wiki/OpenVPN
- https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage

### Certificates

- Install [Easy-RSA](https://github.com/OpenVPN/easy-rsa/releases)
- Generate CA
- Generate and sign server certificate, CN=hostname
- Generate and sign client certificates

### In the router

- Install CA, server certificate, server key
- Allow tcp/1194 in Firewall
- Add new IP Pool
- Add new PPP Profile
- Enable OVPN in PPP / Interface / OVPN Server
- Add users in PPP / Secrets

### On the client

- Install OpenVPN
- Import configuration
- Test connection
