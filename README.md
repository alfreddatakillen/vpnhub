# vpnhub

Install and configuration scripts for setting up an VPN server.

Features:

* OpenVPN 2.x

Prerequisites:

* A fresh install of a modern Ubuntu or Debian.

## Install on Ubuntu 16.04 (will probably work on other versions and on Debian)

1. Clone the repo.
2. Run ./setup.sh
3. Violà!

## Install on Amazon Lightsail

Create an Amazon Lightsail instance, using the "Ubuntu 16.04 LTS" base OS image.
The smallest instance plan is adequate for starters.

Copy-paste this code as your "Lauch Script":

		apt-get -y update
		apt-get -y install git
		git clone https://github.com/alfreddatakillen/vpnhub /opt/vpnhub
		/opt/vpnhub/setup.sh


