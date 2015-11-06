#!/bin/bash
#
# This will run nslookup for all 5 char domain name combinations and output 
# a list of those that did not reply to a ping.
#

# check a-z
for x in {a..z}{0..9},{a..z}{0..9},{a..z}{0..9}; do
	lookup=$(nslookup $x.com | grep -c "** server")
		if [ "$lookup" == "0" ]; then
			echo "$x.com is available"
			echo "$x.com" >> list.txt
		else
			lookup=$(nslookup $x.org | grep -c "** server")
				if [ "$lookup" == "0" ]; then
					echo "x.org is available"
					echo "$x.org" >> list.txt
				else
					lookup=$(nslookup $x.net | grep -c "** server")
						if [ "$lookup" == "0" ]; then
							echo "$x.net is available"
							echo "$x.net" >> list.txt
						else
							echo "no variant of $x is available"
						fi
				fi
		fi
done

