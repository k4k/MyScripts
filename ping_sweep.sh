#!/bin/bash
# Author: Ted Wood
# Date: 2013-09-20

## USER SETTINGS
# You may need to change your network interface
IFACE="en5"

## USAGE: ping_sweep.sh IP_RANGE (OUT_FILE)
## IP_RANGE = class C subnet without trailing "."
## OUT_FILE is optional, specifies outputfile. Default is ping.out


## BEGIN FUNCTION DEFINITIONS

USAGE() {
	echo -e $"\
Usage: $0 IP_RANGE (OUT_FILE) \
\n\t\tIP_RANGe = class C subnet without trailing '.' \
\n\t\tOUT_FILE is optional. Specifies output file name. Default is ping.out \
\n\nYOU MUST RUN THIS SCRIPT AS ROOT"
}

## END FUNCTION DEFINITIONS

# check that script is run as root (otherwise will not work
me=$(id | awk '{print $1}')
if [ "$me" != "uid=0(root)" ]; then
	USAGE
	exit 1
fi

# check that subnet was defined
if [ -z "$1" ]; then
	USAGE
	exit 2
fi
SUB=$1

# check for custom output file
if [ ! -z "$2" ]; then
	OUT="$2"
else
	OUT="ping.out"
fi

# begin ping sweep
for IP in {1..254}; do
	HOST="$SUB.$IP"
	ping -W 1 -q -c 1 "$HOST" > /dev/null
	if [ $? != 0 ]; then
		/usr/local/sbin/arping -c 1 -I "$IFACE" "$HOST" > /dev/null
		if [ $? != 0 ]; then
			HOSTNAME=$(nslookup "$HOST" | awk '/name/ {print $4}')
			if [ ! -z "$HOSTNAME" ]; then
        for i in $HOSTNAME; do
				  echo "$HOST -- $i"
				  echo -e "$HOST, $i" >> $OUT
        done
			else
				echo "$HOST -- NO DNS ENTRY"
				echo -e "$HOST, NO DNS ENTRY" >> $OUT

			fi
		fi
	fi
done
