# vpnhub

Install and configuration scripts for setting up the VPN server

## Install

First, get yourself a fresh install of Debian or Ubuntu. Then, as root:

	apt-get -y update
	apt-get -y install git
	git clone https://github.com/alfreddatakillen/vpnhub /opt/vpnhub
	/opt/vpnhub/setup.sh

Violà!

### Debian yada yada

On Debian, you might have to run

	/lib/systemd/system-generators/openvpn-generator server
	systemctl enable openvpn@server.service
	systemctl restart openvpn@server.service

(The `server` string above is a reference to the config file named
`server.conf` in `/etc/openvpn`. So you might have to do the same on the client
if the client is a Debian, but then change `server` to `client` on all the
rows above.)

### Route traffic to the Internet over the VPN

Add this row on the client's `client.conf` to route all it's traffic through
the VPN:

	redirect-gateway def1

Support must be added to the server also:

	echo 1 > /proc/sys/net/ipv4/ip_forward
	iptables -I FORWARD -i tap0 -o eth0 -s 10.11.12.0/24 -m conntrack --ctstate NEW -j ACCEPT
	iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -t nat -I POSTROUTING -o eth0 -s 10.11.12.0/24 -j MASQUERADE

## Create client configurations

To create configuration for users:

	/opt/vpnhub/create-client.sh bobby vpn.example.org

Where `bobby` is a unique identifier for the user, and `vpn.example.org` is
the hostname for the VPN server.

This will create the file `bobby.tar.bz2` in your current working dir.
The tarball contains all configuration and keys needed for bobby to connect
to the VPN.

