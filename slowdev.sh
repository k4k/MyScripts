#!/bin/bash
#
# This script is designed to slow down an interface ($1) to a default rate
# of 128kbps or to a specified speed ($2)
#

usage () {
	echo -e  \
"\nThis script will create a virtual interface with a unique IP \
address that will the be throttled to ${defspd}kbps or a value defined \
by the user.\n \
\n \
Usage:\n \
\t$0 start eth0\n \
\t\tCreate a virtual interface on the same network as eth0 and \
throttle it to ${defspd}kbps.\n \
\n \
\t$0 start eth0 500\n \
\t\tCreate a virtual interface on the same network as eth0 and \
throttle it to 500kbps."
}

if [ $# -lt 2 ]; then
	usage
fi

## This is old code, leaving here for those interested. It allows the
## script to work semi-intelligently to figure out the right interface.
# Set this to a value unique to your network. For example, if the network
# is 192.168.15.0/24 the value of "net" should be "192.168.15"
#net="PUT SOMETHING HERE"
#netdev=$(ifconfig | grep "$net" -C3 | head -n1 | awk -F: '{print $1}')

iprange=(2 3 4 5 6 7) # space seperated list of fourth octet numbers
netdev=$2
devip=$(ifconfig "$netdev" | awk '/inet / {print $2}')
devnet=$(echo $devip | awk -F. '{print $1"."$2"."$3"."}')

defspd="${3:-128}"
case $1 in
	start)
		for ip in "${iprange[@]}"; do
			vrtip=
			ping -c1 -t1 ${devnet}${ip}
			if [ "$?" ! -eq "0" ]; then
				arping -c1 ${devnet}${ip}
				if [ "$?" -eq "1" ]; then
					vrtip="${devnet}${ip}"
					break
				fi
			fi
		done
		if [ -z $vrtip ]; then
			echo "No free IPs found"
			exit 1
		fi
		ifconfig ${netdev}:0 $vrtip
		tc qdisc add dev ${netdev}:0 handle 1: root htb default 11
		tc class add dev ${netdev}:0 parent 1: classid 1:1 htb rate ${defspd}kbps
		tc class add dev ${netdev}:0 parent 1:1 classid 1:11 htb rate ${defspd}kbps
		;;

	stop)
		tc qdisc del dev ${netdev}:0 root
		ifconfig ${netdev}:0 down
		;;

	*)
		usage
esac
