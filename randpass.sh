#!/bin/bash
#
# Generate a random password of specified length
# Wrtten by: Ted Wood (ted.l.wood@gmail.com)
# Date: 2011-06-14
# Version: 1.0
#

# Set default length
good() {
	length="12"

# Prompt user for alternate length
		read -p "Enter desired password legth [$length]: " length2
		if [ ! -z $length2 ]
			then
				length=$length2
				fi

# Generate password using length specified above
				cat /dev/urandom| tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='|fold -w $length| head -n 4| grep -i '[!@#$%^&*()_+{}|:<>?=]'
}

# Have another way to run it because comcast is shitty and has a maximum
# password limit and probably stores your password in plain text
# So, no matter how complex we make it, your shit will still get owned
comcast() {
	cat /dev/urandom| tr -dc 'a-zA-Z0-9-_!@#$%^&*'|fold -w 16| head -n 4| grep -i '[!@#$%^&*()_+{}|:<>?=]'
}

case "$1" in
comcast|shitty|short)
comcast
;;
good|long|secure)
good
;;
*)
echo -e $"\
Usage: $0 {good | comcast} \
\n\tgood or long or secure \
\n\t\tCreates password of user specified length that is very secure \
\n\tcomcast or shitty or short \
\n\t\tCreates a password that meets that maximum allowed limit for comcast plain text password database \
\n\t\t(very inseucre, tisk tisk)"
RETVAL=1
esac
