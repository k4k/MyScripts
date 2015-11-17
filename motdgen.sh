#!/bin/bash
#
# This script is designed to run as a cron.hourly job
# Script requires two packages. On Fedora/Redhat these packages are called
# "sysstat" and "figlet". They might be different on your platform.
# This script creates /etc/motd by passing the hostname through figlet to 
# generate a fancy graphic of the name. It then gets the CPU info from
# /proc/cpuinfo, memory statistics from the `free` command, user statistics
# from the `uptime` command and System stats from the `sar` command.
#
# The CPU, Memory, Users and System fields appear misaligned in echo but they
# should print out correctly. You can adjust if necessary but I suggest leaving
# them as they are.

# Output File (default is /etc/motd)
out_file="/etc/motd"


echo "-------------------------------------------------------------------------------

$(hostname | figlet)
-------------------------------------------------------------------------------

CPU:$(cat /proc/cpuinfo | awk -F: '/model name/ {print "\011""\011""\011"$2}')
Memory:	 		 $(free -m | grep Mem: | awk '{print $3"/"$2}') MB
Users:		       $(uptime | cut -d, -f3)
System:			 $(sar | tail -n 1)
-------------------------------------------------------------------------------" > $out_file
