#!/bin/bash

# This script was written as a shortcut to "resetting" a RHEL6 VM template
# Resetting the template involves resetting the network interfaces, changing
# the systems hostname, registering the system to spacewalk, pulling the config
# for the new node from puppet and re-registering the system to Free-IPA using
# the system's new hostname information.

## Set these variables to match your environment
# Spacewalk Server Address
_SPACEWALK_SRV=""
# Spacewalk Activation Key
_SPACEWALK_KEY=""
# FreeIPA Server Address
_FREEIPA_SRV=""
# Puppet Server Address
_PUPPET_SRV=""
# Your Domain
_DOMAIN=""
# IPA CA FILE PATH
_FREEIPA_CA=""


## You shouldn't need to change anything below this point

## Set some dynamic variables
_USERNUM="$(id -u)"
_NEWNAME="$1"
_CURFQDN=$(facter fqdn)
_CURSHORT=$(facter hostname)
_REALFQDN=$("${_NEWNAME}"."${_DOMAIN}")

## Functions
# If variable is missing, use this.
noVar() {
	echo -e "Please make sure you have set all of the required user variables"
}

# If invalid option is presented, use this
usage() {
	echo -e "Usage: \
		\n\t$0 Shortname-of-newhost"
}

# If permissions issue occurs
permErr() {
	echo -e "Please ensure that you are root and try again"
}

# Network Reset
netReset() {
	netFile1="/etc/udev/rules.d/70-persistent-net.rules"
	netFile2="/etc/sysconfig/network/devices/ifcfg-eth0"
	netFile3="/etc/sysconfig/network/profiles/default/ifcfg-eth0"
	netFile4="/etc/sysconfig/network-scripts/ifcfg-eth0"

	if [ -f "$netFile1" ]; then
		rm -Rf "$netFile1"
	fi
	for file in "$netFile2" "$netFile3" "$netFile4"; do
		sed -i '/^UUID.*$/d' "$file"
		sed -i '/^HWADDR.*$/d' "$file"
		sed -i "s/^HOSTNAME.*\$/HOSTNAME=\"$_NEWNAME\"/" "$file"
	done
}

# Change Hostname
updateName() {
	sed -i "s/^HOSTNAME.*\$/HOSTNAME="$_NEWNAME"."$_DOMAIN"/" /etc/sysconfig/network
	sed -i "s/\"$_CURSHORT\"/\"$_NEWNAME\"/g" /etc/hosts
}

# Spacewalk Registration
rhnReg() {
	rhnreg_ks --serverUrl "$_SPACEWALK_SRV" --activationkey "$_SPACEWALK_KEY" --force
}

# Puppet
puppetReg() {
	if [ "$_CURFQDN" != "$_REALFQDN" ]; then
		echo "domain \"$_REALFQDN\" >> /etc/resolv.conf"
	fi
	rm -Rf /var/lib/ssl/* # Remove any old certs that might conflict
	ntpd -s "$_FREEIPA_SRV" # Sync with ntp server (assumed to be FreeIPA server)
	puppet agent -t --server "$_PUPPET_SRV"
}

# IPA
ipaReg() {
	# De-register
	ipa-client-install --uninstall # De-register from IPA
	# Register
	ipa-client-install \
		--domain="$_DOMAIN" \
		--server="$_FREEIPA_SRV" \
		--ca-cert-file="$_FREEIPA_CA" \
		--fixed-primary
}


# Check that hostname was given
if [ -z "$!" ]; then
	usage
	exit 1
fi

# Check for mandatory variable values
if [ -z "$_SPACEWALK_SRV"] \
|| [ -z "$_SPACEWALK_KEY" ] \
|| [ -z "$_DOMAIN" ] \
|| [ -z "$_FREEIPA_CA" ] \
|| [ -z "$_FREEIPA_SRV" ] \
|| [ -z "$_PUPPET_SRV" ]; then
	noVar
	exit 2
fi

if [ "$_USERNUM" != "0" ]; then
	permErr
	exit 3
fi



exit 0
