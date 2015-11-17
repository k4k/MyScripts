## Author: Ted Wood
## Email: ted.l.wood@gmail.com
## Date: 2012-10-04
###############################################################################
## Since the acpitool project page has been down for some time, I've re-written
## This utility to use the generic acpi utility. You can get this from
## slackbuilds.org, if you are running slackware, or from your distributions'
## prefered package management system.
#
## If you wish to use the acpitool method instead of the acpi method, uncomment
## out the "ACPITOOL" section and comment out the "NO ACPITOOL" section.
## If you wish to use the acpitool method instead of the acpi method, change
## use_acpi in the user variables section to false.
#
## Update: I've tested this on Fedora 23 on a Macbook Pro Retina most recently
##         and discovered that `acpitool -B` was not reporting any batteries
##         present on the system. YMMV
#
###############################################################################

## User variables
batId="0" # You might need to change this if your battery id is not 0 (unlikely)
use_acpi=true

which acpiconf > /dev/null 2>&1
if [ "$?" != "1" ]; then
	### ACPICONF
	# This will work on BSD systems that use the acpiconf utility instead of acpitool
	percent=$(acpiconf -i ${batId} | grep "Remaining capacity:" | awk '{print $3}')
	time=$(acpiconf -i ${batId} | grep "Remaining time:" | awk '{print $3}')
	echo "${percent} | ${time}"
fi

## Functions
# ACPITOOL
use_acpitool() {
	acpitool -B | grep Remaining | awk '{print $6 " " $7}'
}

# NO ACPITOOL
no_acpitool() {
	#Check if plugged in
	plug=$(acpi -a | awk '{print $3}')
	# If not plugged in, show time remaining
	if [ "$plug" = "off-line" ]; then
		acpi -b | awk -F, '{print $2 $3}' | awk '{print $1" - "$2}'
		#If plugged in, only show percentage
	elif [ "$plug" = "on-line" ]; then
		acpi -b | awk '{print $4}'
		#This should never happen, but if it does, add a condition for it
	else
		echo "NULL"
	fi
}

if ! ${use_acpi}; then
	no_acpitool
else
	use_acpitool
fi
