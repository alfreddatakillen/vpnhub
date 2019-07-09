#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Must be root."
	exit 1
fi

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

# Create ccd directory:
mkdir -p /etc/openvpn/ccd

# VPN config:
cat >/etc/openvpn/server.conf <<_EOF_
port 443
proto udp
dev tap
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh1024.pem
server 10.11.12.0 255.255.255.0
ccd-exclusive
client-config-dir /etc/openvpn/ccd
client-to-client
keepalive 1 8 
tls-auth /etc/openvpn/ta.key 0
comp-lzo
max-clients 100
float
user nobody
group nogroup
persist-key
persist-tun
script-security 2
up /etc/openvpn/up.sh
_EOF_

cat >/etc/openvpn/up.sh <<_EOF_
#!/bin/bash

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

#
# Here, you can add port forwarding:
#
#iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 22 -j DNAT --to-destination 10.11.12.6:22
#iptables -A FORWARD -p tcp -d 10.11.12.6 --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#

iptables -I FORWARD -i tap0 -o eth0 -s 10.11.12.0/24 -m conntrack --ctstate NEW -j ACCEPT
iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -I POSTROUTING -o eth0 -s 10.11.12.0/24 -j MASQUERADE
_EOF_

# File permissions:
chmod 400 /etc/openvpn/*
chmod 444 -R /etc/openvpn/ccd
chmod 555 /etc/openvpn/ccd
chmod a+x /etc/openvpn/up.sh

# Enable IP4 forwarding
sysctl -w net.ipv4.ip_forward=1

# Restart server
service openvpn restart
