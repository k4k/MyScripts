#!/bin/bash 
#
# This script will make an Atomic host on a system using kvm/libvirt
# You must provide at least the -n (or --name) and -d (or --disk) arguments
#
# The optional flags (-r, -s, -c, -b and -p) are not all required. For example,
# if you only need to set a custom ram size and password, you can use just -r
# and -p.
#
# There is a --clean flag that can be used with the -n flag to clean-up
#
# The script works well if you create a working directory for Atomic.
# For example, make a directory ~/Atomic and always run this script while in
# that directory. In this way, the script can keep all working files nicely
# organized. If you consistently work inside of you ~/Atomic directory, the
# cleanup function of this script can much more effecitvely keep your filesystem
# tidy.
# =========================================================================== #

## Standard Functions
usage() {
	echo -e "\
Usage:\n\
\t${0} -n Guest-Name -d Path-to-qcow2-file\n\
\t${0} -n Guest-Name -d qcow2-file -r ramsize -s disksize -c cpus -b bridge -p userPassword\n\n\
Example:\n \
\t${0} -n C7-Atomic -d /tmp/CentOS-Atomic.qcow2\n\
\t${0} -n C7-Atomic -d /tmp/CentOS-Atomic.qcow2 -r 1024 -d 15 -c 4 -b br0 -p At0mic_pass"
}

atomicClean() {
	virsh destroy "${_NAME}"
	virsh undefine "${_NAME}"
	if [ -d ./${_NAME} ]; then
		rm -rf ./${_NAME}
	fi
}

## Exit on any error
set -o errexit

## Parse through the command line switches
## If there are 3, assume cleanup operation
if [ "$#" -eq 3 ]; then
	while [[ $# > 0 ]]; do
		key="$1"

		case $key in
			-n|--name)
				_NAME="${2}"
				shift
				shift
				;;
			--clean)
				_ACTION="clean"
				shift
				;;
			*)
				usage
				exit 1
				;;
		esac
	done
	case "${_ACTION}" in
		clean)
			atomicClean
			;;
		*)
			;;
	esac
	echo "Removed ${_NAME} from inventory"
	exit 0
fi

## If there are 4, assume we want to make an atomic VM
if [ "$#" -lt "4" ]; then
	usage
	exit 2
fi
while [[ $# > 1 ]]; do
	key="$1"

	case $key in
		-n|--name)
			_NAME="${2}"
			shift
			;;
		-d|--disk)
			_DISK="${2}"
			shift
			;;
		-r|--ram)
			_RAMSIZE="${2}"		# IN MB
			shift
			;;
		-s|--size)
			_DISKSIZE="${2}"	# IN GB
			shift
			;;
		-c|--cpu)
			_VCPUS="${2}"			# NUM of CPUs
			shift
			;;
		-b|--bridge)
			_BRIDGE="${2}"
			shift
			;;
		-p|--pass)
			_PASSWORD="${2}"
			shift
			;;
		*)
			usage
			;;
	esac
shift
done


# Fill in the variables that were not set by the user with default values
# You can tune these if you want
if [ -z "${_PASSWORD}" ]; then
	_PASSWORD="At0mic"
fi
if [ -z "${_BRIDGE}" ]; then
	_BRIDGE="virbr0"
fi
if [ -z "${_VCPUS}" ]; then
	_VCPUS="1"
fi
if [ -z "${_DISKSIZE}" ]; then
	_DISKSIZE="10"
fi
if [ -z "${_RAMSIZE}" ]; then
	_RAMSIZE="2048"
fi
_BASEDIR="$(pwd)"
if [ ! -d ${_BASEDIR}/${_NAME} ]; then
	mkdir ${_BASEDIR}/${_NAME}
fi
cp ${_DISK} ${_BASEDIR}/${_NAME}/${_DISK}
_TMPISO="${_BASEDIR}/${_NAME}/init.iso"
_TMPDISK="${_BASEDIR}/${_NAME}/$(basename ${_DISK})${RANDOM}"

## Should not need to edit below this line
## Unless you want to add content to the meta-data or user-data files

_USERDATA="
#cloud-config
password: ${_PASSWORD}
chpasswd: { expire: False }
ssh_pwauth: True
ssh_authorized_keys:
  - \"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUJOv/gB++1OAM79vy+7ZwnZ2G4h+CjoLNS+AKO9t6V elw@mbp\"
"

_METADATA="
instance-id: ${_NAME}
local-hostname: ${_NAME}
"

echo "Creating user data iso ${_TMPISO}"
pushd $(mktemp -d)
echo "Making user-data"
echo "${_USERDATA}" > user-data
echo "Making meta-data"
echo "${_METADATA}" > meta-data
if [ -f user-data ] && [ -f meta-data ]; then
	genisoimage -output ${_TMPISO} -volid cidata -joliet -rock user-data meta-data
else
	echo "Missing meta-data and user-data files. Exiting..."
	exit 1
fi
popd

echo "Creating snapshot disk ${_TMPDISK}"
qemu-img create -f qcow2 -b "${_BASEDIR}/${_DISK}" "${_TMPDISK}" ${_DISKSIZE}G

# Build up the virt-install command
cmd='virt-install --import'
cmd+=" --name ${_NAME}"
cmd+=" --ram ${_RAMSIZE}"
cmd+=" --vcpus ${_VCPUS}"
cmd+=" --disk path=${_TMPDISK}"
cmd+=" --disk path=${_TMPDISK}2,size=${_DISKSIZE}"
cmd+=" --disk path=${_TMPISO}"
cmd+=" --accelerate"
cmd+=" --graphics none"
cmd+=" --force"
cmd+=" --network bridge=${_BRIDGE},model=virtio"

#Run the command
echo "Running: ${cmd}"
${cmd}
