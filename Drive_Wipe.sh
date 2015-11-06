#!/bin/bash

#
##
### WARNING: THIS SCRIPT WILL WIPE WHATEVER DRIVE YOU SELECT, USE CAUTION
##
#

#!/bin/bash
raw=$(mount -l | grep /media | awk '{print $3}')
device=$(mount -l | grep $drive | awk '{print $1}')
echo
read -p "We have found the following removable devices:
$raw

If your device is not listed here you may select another drive by typeing in the device name 'eg. /dev/sda' at the prompt.

What device would you like to wipe? :" drive
for n in `seq 7`; do
	device=$(mount -l | grep $drive | awk '{print $1}')
	dd if=/dev/urandom of=$device bs=8b conv=notrunc
done
