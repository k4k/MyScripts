#!/bin/bash

BINDDN="uid=xxxx,ou=XXX,ou=xxxxx,dc=xxxxx,dc=xxxx,dc=xxx"
_LDAP_URI="Fully Qualified LDAP URI here"
_PPL_OU="ou for the people"

read -s -p "LDAP [$BINDDN] password: " bindpw
echo

uid="$1"
if [ -z "$uid" ]
then
	read -p "User ID: " uid
fi

IFS=$'\n'

cn=""
dn=""
gecos=""

(
	for line in `ldapsearch -LLL -x -H "${_LDAP_URI}" -b "${_PPL_OU}" "(&(!(uidNumber=*))(uid=$uid))" dn cn`
	do
		if [ "${line%%:*}" = "dn" ]
		then
			dn="$line"
		elif [ "${line%%:*}" = "cn" ]
		then
			cn="${line#cn: }"

			gecos="$cn"
			if [[ "$gecos" =~ (Jr|Sr|I|II|III|IV)( --.*)?$ ]]
			then
				gecos=`echo "$gecos" | sed -re 's/^([^,]+), ([^-]+)( (Jr|Sr|I|II|III|IV))( --.*)?$/\2 \1\3/' -e 's/\.\././'`
			else
				# this sed cleans up double .'s and the "--$UID" seen in some CNs (which were copied to gecos)
				gecos=`echo "$gecos" | sed -re 's/^([^,]+), ([^-]+)( --.*)?$/\2 \1/' -e 's/\.\././'`
			fi
		fi

		if [ "${#dn}" -gt 0 -a "${#cn}" -gt 0 ]
		then
			foo="${dn#dn: uid=}"
			uid="${foo%%,*}"
			cat <<-EOR
			$dn
			changetype: modify
			add: objectclass
			objectclass: posixAccount
			-
			add: uidNumber
			uidNumber: 99999
			-
			add: gidNumber
			gidNumber: 100
			-
			add: homeDirectory
			homeDirectory: /users/$uid
			-
			add: loginShell
			loginShell: /bin/bash
			-
			add: gecos
			gecos: $gecos
			EOR
			echo

			cn=""
			dn=""
		fi
	done
) | ldapmodify -v -x -H ${_LDAP_URI} -D "$BINDDN" -w "$bindpw"
