#!/bin/bash
#
# Please contact support if you have any problems with
# mounting your network shares.
#
# Originally written by Josh Kayse and modified by Ted Wood

##### Default settings

## Guess correct info
user_name=$(whoami)
## relace with line below if the above consistantly guesses incorrectly
# user_name="AD_USERNAME"

## Change this to be your AD domain
domain=""

start() {
	## Check if user guess is correct
	read -p "Enter your Username [$user_name]: " user_name2

	## If no username entered, use guess
	if [ ! -z $user_name2 ]
	then
		user_name=$user_name2
	fi

	## Mount Shares
	for share in Share1 Share2
	do
		echo "Mounting $share"
		gvfs-mount "smb://$domain;$user_name@<YOUR SERVER HERE>/$share"

	done
}

stop() {
	# Unmount the mountpoints
	for share in Share1 Share2
	do
		gvfs-mount -u "smb://$domain;$user_name@<YOUR SERVER HERE>/$share"
	done
}

case "$1" in
	mount|start)
		start
		;;
	unmount|umount|stop)
		stop
		;;
	remount|restart)
		stop
		start
		;;
	*)
		echo -e $"\
Usage: $0 {mount | umount | remount} \
\n\tmount or start \
\n\t\tMounts Windows shares \
\n\tumount or unmount or stop \
\n\t\tUnmounts Windows shares \
\n\tremount or restart \
\n\t\tUnmounts then mounts Windows shares"
                RETVAL=1
esac

