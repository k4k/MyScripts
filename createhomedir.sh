#! /bin/bash
#
## Check if 'ldap-clients' is installed. If it is, proceed to step two. 
## Else install package 'ldap-clients' and proceed.

prog_check=$(which ldapsearch | grep -c /usr/bin/ldapsearch)
while [ $prog_check = 0 ];do
	## Check if ldap-clients is available before download
	exists=$(su -c "yum search ldap-clients | grep -c 'LDAP client utilities'")
	if [ "$exists" != "0" ];then
		su -c "yum -y install ldap-clients"
	else
		echo "The ldap-client does not appear to be available"
		exit 0
	fi
done;
for home in $(ldapsearch -LLL -x -H <LDAP SERVER URI HERE> -b dc=xxxx,dc=xxxx,dc=xxx '(objectclass=posixAccount)' homeDirectory | grep homeDirectory | awk '{print $2}'); do ( mkdir $home && cp -R /etc/skel/. $home && chown `echo "$home" | cut -d "/" -f 3`.users $home);done;
exit 0	
