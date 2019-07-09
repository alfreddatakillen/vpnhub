#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Must be root."
	exit 1
fi

if [ "$1" = "" ]; then
	echo "First parameter must be the name (a-z only) for a client."
	exit 1
fi

if [ "$2" = "" ]; then
	echo "Second parameter must be the host/dns/ip for the VPN server."
	exit 1
fi

if [[ $1 =~ ^[A-Za-z_]+$ ]]; then
	echo "Generating config for client: $1"
else
	echo "Client name must be a-z letters only."
	exit 1
fi

if [ -e "$1.tar.bz2" ]; then
	echo "File already exists: $1.tar.bz2"
	exit 1
fi

TMPDIR="$(tempfile)"
rm "$TMPDIR"
mkdir -p "$TMPDIR/openvpn"

# Create and sign the client cert:
openssl genrsa -out $TMPDIR/openvpn/client.key 4096
openssl req -new -key $TMPDIR/openvpn/client.key -subj "/CN=$1" -out $TMPDIR/openvpn/client.csr
openssl x509 -req -in $TMPDIR/openvpn/client.csr -CA /etc/openvpn/ca.crt -CAkey /etc/openvpn/ca.key -out $TMPDIR/openvpn/client.crt -days 1024 -sha256

# Copy dh and ta keys and the ca:
cp /etc/openvpn/ca.crt $TMPDIR/openvpn/ca.crt
cp /etc/openvpn/dh1024.pem $TMPDIR/openvpn/dh1024.pem
cp /etc/openvpn/ta.key $TMPDIR/openvpn/ta.key

# VPN config:
cat >$TMPDIR/openvpn/client.conf <<_EOF_
client
remote $2
port 443
proto udp
resolv-retry infinite
dev tap
ca /etc/openvpn/ca.crt
cert /etc/openvpn/client.crt
key /etc/openvpn/client.key
dh /etc/openvpn/dh1024.pem
keepalive 5 30
tls-auth /etc/openvpn/ta.key 1
comp-lzo
nobind
persist-key
persist-tun
verb 3
_EOF_

# Set IP for the client:
if [ -e /etc/openvpn/ccd/$1 ]; then
	rm /etc/openvpn/ccd/$1
fi
ip=2
while [ "$(cat /etc/openvpn/ccd/* 2>/dev/null | grep "10.11.12.$ip")" != "" ]; do
	ip=$((ip+1))
done
echo "ifconfig-push 10.11.12.$ip 255.255.255.0" >/etc/openvpn/ccd/$1
chmod 444 -R /etc/openvpn/ccd
chmod 555 /etc/openvpn/ccd

# File permissions:
chmod 400 $TMPDIR/openvpn/*
pushd $TMPDIR
tar cjvf $1.tar.bz2 openvpn
popd >/dev/null
mv $TMPDIR/$1.tar.bz2 .

# Clean-up
rm -Rf $TMPDIR

