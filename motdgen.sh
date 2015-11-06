#!/bin/bash
#
# This script is designed to run as a cron.hourly job
# Script should grab the output from the uptime command and then parse
# the results into information to be inserted into /etc/motd
#

# Delete the old MOTD file if it exists
if [ -a motd ]
  then
    rm -Rf motd
fi

echo "-------------------------------------------------------------------------------

$(hostname | figlet)
-------------------------------------------------------------------------------

CPU:            Intel(R) Xeon(R) CPU            3060  @ 2.40GHz
                Intel(R) Xeon(R) CPU            3060  @ 2.40GHz
Memory		$(free -m | grep Mem: | awk '{print $3"/"$2}') MB
Users:		$(uptime | cut -d, -f3)
System $(sar | tail -n 1)
-------------------------------------------------------------------------------" > motd.txt
