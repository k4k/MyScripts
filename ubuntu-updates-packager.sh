#!/bin/bash

# MD5SUM all packages inside the Ubuntu package repository and bundle the
# packages that have been updated in to a tarball and place them on the
# web server for download.
#
# The first run of this script will create a tarball of every package found
# because there is no baseline to compare against. The second time it runs
# it will compare to the last run (assuming $sumsfile exists from the previous
# run). If you don't want this to happen, run:
#		`find $dir_list -type f -exec md5sum {} \; >> $tmp/repo_sums`
# by hand before running this script for the first time

## Change these to match your environment
repo_path="/mnt/repo/ubuntu/dists"
code_name="trusty"
tmp="/tmp"
dir_list="${code_name} ${code_name}-backports ${code_name}-proposed ${code_name}-security ${code_name}-updates"
outfile="${code_name}_updates.tar.gz"
outpath="${repo_path}"
sumsfile="$tmp/repo_sums"

if [ ! -d $repo_path ]; then
	echo "The path you have set for \$repo_path is not valid"
	exit 1
fi

if [ ! -d $repo_path/$code_name ]; then
	echo "You do not have a repo available in $code_name in $repo_path"
	exit 2
fi

if [ ! -d $tmp ]; then
	mkdir $tmp
	if [ $? -ne 0 ]; then
		echo "$tmp directory does not exist and attempts to create it have failed..."
		exit 3
	fi
fi

cd $repo_path

if -f $sumsfile; then
	mv $sumsfile ${sumsfile}.bak
fi

find $dir_list -type f -exec md5sum {} \; >> $sumsfile
if [ -f ${sumsfile}.bak ]; then
	difflist=$(diff -c $sumsfile ${sumsfile}.bak | awk '/\!/ {print $3}' | tr -d '()' | tr ' ' '\n'|sort -u|tr '\n' ' ')
	tar -czvf ${outpath}/${outfile} ${difflist}
else
	echo "Unable to create diff or tarball. Is this your first time running the script?"
	exit 4
fi

exit 0
