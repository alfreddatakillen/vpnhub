#!/bin/bash
type openvpn >/dev/null 2>&1 || apt-get -y install openvpn

# Create certification agency:
[ -f /etc/openvpn/ca.key ] || openssl genrsa -out /etc/openvpn/ca.key 4096
[ -f /etc/openvpn/ca.crt ] || openssl req -batch -x509 -new -nodes -key /etc/openvpn/ca.key -sha256 -days 1024 -out /etc/openvpn/ca.crt

# Create and sign the server cert:
[ -f /etc/openvpn/server.key ] || openssl genrsa -out /etc/openvpn/server.key 4096
[ -f /etc/openvpn/server.csr ] || openssl req -new -key /etc/openvpn/server.key -subj "/CN=server" -out /etc/openvpn/server.csr
[ -f /etc/openvpn/server.crt ] || openssl x509 -req -in /etc/openvpn/server.csr -CA /etc/openvpn/ca.crt -CAkey /etc/openvpn/ca.key -CAcreateserial -out /etc/openvpn/server.crt -days 1024 -sha256

# Diffie Hellman and ta:
[ -f /etc/openvpn/dh1024.pem ] || openssl dhparam -out /etc/openvpn/dh1024.pem 1024
[ -f /etc/openvpn/ta.key ] || openvpn --genkey --secret /etc/openvpn/ta.key

# VPN config:
cat >/etc/openvpn/server.conf <<_EOF_
port 443
proto tcp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh1024.pem
server 10.160.0.0 255.255.255.0
client-to-client
keepalive 5 30
tls-auth /etc/openvpn/ta.key 0
comp-lzo
max-clients 10
user nobody
group nogroup
persist-key
persist-tun
_EOF_

# File permissions:
chmod 400 /etc/openvpn/*

# Restart service!
systemctl restart openvpn@server.service

