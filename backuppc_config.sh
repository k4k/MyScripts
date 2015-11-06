#!/bin/bash
#
# To assist with the configuration of BackupPC on client computers
# 
# Author: Ted Wood
# Date: 2011-06-27
#

## BEGIN INITIAL GET FILES
new () {
me=$(id | awk '{print $1}')
if [ "$me" != "uid=0(root)" ]
	then
	echo -e "\n\nYou need to be root to run this script."
	exit 1
fi

# Create backup_pc user
    echo "Creating user \"backup_user\"..."
    useradd -d /home/backup_user -m -s /bin/bash -U backup_user
    
# Make .ssh directory inside of /home/backup_user
    mkdir /home/backup_user/.ssh
    chown backup_user.backup_user /home/backup_user/.ssh
    chmod 0700 /home/backup_user/.ssh
    echo "Done"
    
# Create /backups directory if it does not already exist
    if [ ! -e /backups ]
    	then
    		echo "Creating /backups directory..."
    		mkdir /backups
# Change permissions on /backups
    		chown backup_user.root /backups
    		chmod 0750 /backups
# Set ACL on /backups
    		setfacl -R -m u:backup_user:rX /backups; setfacl -d -R -m u:backup_user:rX /backups
    		echo "Done"
# Continue if /backups alrady exists
    	else
    		echo -e $"\
\n\nIt appears that the directory /backups already exists, please \
\nsee the instructions located at \
\n<YOUR URL HERE> \
\nbackups on this computer."
    		exit 1
    fi
    
    echo "Collecting configuration files for BackupPC..."
    
# Get authprogs from Server
    wget --no-check-certificate https://<YOUR URL HERE>/pub/common/authprogs -O /usr/local/bin/authprogs
    chown root.root /usr/local/bin/authprogs
    chmod 0755 /usr/local/bin/authprogs
    echo "Successfully downloaded /usr/loca/bin/authprogs..."
    
# Get authprogs.conf
    wget --no-check-certificate https://<YOUR URL HERE>/pub/common/authprogs.conf -O /home/backup_user/.ssh/authprogs.conf
    chown backup_user.root /home/backup_user/.ssh/authprogs.conf
    chmod 0400 /home/backup_user/.ssh/authprogs.conf
    echo "Successfully downloaded /home/backup_user/.ssh/authprogs.conf..."
    
# Get authorized_keys
    wget --no-check-certificate https://<YOUR URL HERE>/pub/common/authorized_keys -O /home/backup_user/.ssh/authorized_keys
    chown backup_user.root /home/backup_user/.ssh/authorized_keys
    chmod 0400 /home/backup_user/.ssh/authorized_keys
    echo "Successfully downloaded /home/backup_user/.ssh/authorized_keys..."
    echo "Done"
    
## END INITIAL GET FILES
    
## BEGIN CUSTOM FILE FOLDER ADDITION
    	
# Prompt if they want to create a custom backup directory
  	#clear
    	read -p "This next section will walk you through a series of questions to specify custom
directories you would like to have backed up. By default /backups has been
configured to be backed up.
Would you like to specify an additional custom directory to back up now? [y/N]: " response
   	if [ -z $response ]
		then
		response="n"
	fi 
    	if [ "$response" = "y" ]
    		then
# Prompt for the directory they want
    		read -p "What directory would you like to back up in addition to /backups? :" addbkp
    			while [ -z $addbkp ]
    				do
# Catch blank entries
    					read -p "It doesn't appear you specified specified a directory.
What directory would you like to back up in additioni to /backups? :" addbkp
    			done
# Check if directory exists
    			while [ ! -e "$addbkp" ]
    				do
# Prompt what to do if it does not "OK" will create the directory
    					read -p "The directory you have specified does not exist.
Please specify another location or type \"ok\" to create it: " addbkp2
    					if [ "$addbkp2" == "ok" OR "$addbkp2" == "OK" ]
    						then
    							mkdir $addbkp
    					else
# If answer is not "OK" then say that new directory is what is to be backed up and try again
    						addbkp=$addbkp2
    					fi
    			done
# Set ACL to give backup_user read access to $addbkp
    setfacl -R -m u:backup_user:rX $addbkp; setfacl -d -R -m u:backup_user:rX $addbkp
    
# Modify the /home/backup_user/.ssh/authprogs.conf to permit the backing up of the new directory
    echo -e $"\n# Special rules for backing up $addbkp\n\tenv LC_ALL=C /bin/gtar -c -v -f - -C $addbkp --totals\n\tenv LC_ALL=C /bin/gtar -x -p --numeric-owner --same-owner -v -f - -C $addbkp\n\tenv LC_ALL=C /bin/gtar -c -v -f - -C $addbkp --totals --newer=NN-N-N\ N:N:N ." >> /home/backup_user/.ssh/authprogs.conf
fi
}
## END CUSTOM FOLDER ADDITION

## BEGIN ADD ADDITIONAL BACKUP DIRECTORIES
add () {
me=$(id | awk '{print $1}')
if [ "$me" != "uid=0(root)" ]
	then
	echo -e "\n\nYou need to be root to run this script."
	exit 1
fi

	read -p "Please enter a directory you wish to be backed up: " addbkp
	while [ -z $addbkp ]
		do
# Catch blank entries
			read -p "it does not appear you specified a directory.
Please enter a directory you wish to be backed up: " addbkp
	done
	while [ ! -e "$addbkp" ]
		do
# Check if directory exists
			read -p "The directory you have entered does not exist.
Please specify another location or type \"ok\" to create it: " addbkp2
			if [ "$addbkp2" = "ok" ]
				then
				mkdir $addbkp
			else
# If answer is not "OK" then say that new directory is what is to be backed up and try again
				addbkp=$addbkp2
			fi
		done

# Set ACL to give backup_user read access to $addbkp
	setfacl -R -m u:backup_user:rX $addbkp; setfacl -d -R -m u:backup_user:rX $addbkp

#Modify the /home/backup_user/.ssh/authprogs.conf to permit the backing up of the new directory
    echo -e $"\n# Special rules for backing up $addbkp\n\tenv LC_ALL=C /bin/gtar -c -v -f - -C $addbkp --totals\n\tenv LC_ALL=C /bin/gtar -x -p --numeric-owner --same-owner -v -f - -C $addbkp\n\tenv LC_ALL=C /bin/gtar -c -v -f - -C $addbkp --totals --newer=NN-N-N\ N:N:N ." >> /home/backup_user/.ssh/authprogs.conf

## END ADD ADDITONAL BACKUP DIRECTORIES
}

# Specify the different cases and usage if now case is giving in $1
case "$1" in
		new|fresh)
			new
			;;
		update|add)
			add
			;;
		*)
			echo -e $"\
Usage: $0 {new | add} \
\n\tnew or fresh \
\n\t\tUse this when running for the first time \
\n\tadd or update \
\n\t\tUse this if you have previously run this script and would like to add additional backup locations"
			RETVAL=1
esac
