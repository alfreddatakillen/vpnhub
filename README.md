# vpnhub
Install and configuration scripts for setting up an Amazon Lightsail as VPN server

## Install

Create an Amazon Lightsail instance, using the "Ubuntu 16.04 LTS" base OS image.
The smallest instance plan is adequate for starters.

Copy-paste this code as your "Lauch Script":

		apt-get -y update
		apt-get -y install git
		git clone https://github.com/alfreddatakillen/vpnhub /opt/vpnhub
		/opt/vpnhub/setup.sh

Violà!

