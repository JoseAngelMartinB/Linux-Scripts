#!/bin/bash
# Created by José Ángel Martín Baos
# ./SecurityCopy.sh Origin_directory Directory_security_copy

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%  (32/32 files copied)
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%  (${1}/${2} files)"

}


# Main Script
if [ ! $# -eq 2 ]
then
	echo "How to use it?  ./SecurityCopy.sh <Origin directory> <Directory for the security copy>"
	exit 1
fi

# Check arguments are correct
for i in $@
do
	if [ ! -d $i ]
	then
		echo "ERROR: $i is not a directory."
		exit 1
	fi
done

whiptail --title "Security copy creator script" --msgbox "This script will allow you to create a security copy of a directory or to update a current security copy of that directory. \n\n
This script has been coded by José Ángel Martín in the year 2017." 0 0

origin_dir=$1
destination_dir=$2
size_dir=`du -hs $origin_dir | cut -f1`
remove_dirs=0
remove_files=0
inverse_copy=0

#Options
OPTIONS=$(whiptail --nocancel --title "Security copy options" --checklist \
"Select the Security copy options using the space bar. Press enter to continue." 0 0 0 \
"REMOVE_DIR" "Remove from the security copy the directories that are not in the origin directory" OFF \
"REMOVE_FILES" "Remove from the security copy the files that are not in the origin directory" OFF \
"INVERSE_COPY" "Update files in origin directory if they have been updated in destination directory" OFF 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
	echo "Options selected:" $OPTIONS
	if [ `echo $OPTIONS | egrep -c REMOVE_DIR` -eq 1 ]
	then
		remove_dirs=1
	fi
	if [ `echo $OPTIONS | egrep -c REMOVE_FILES` -eq 1 ]
	then
		remove_files=1
	fi
	if [ `echo $OPTIONS | egrep -c INVERSE_COPY` -eq 1 ]
	then
		inverse_copy=1
	fi
else
	echo "Aborting the execution of the script..."
	exit 1
fi	


# Ask the user to confirm the operation
if (whiptail --title "Start security copy?" \
--yesno "The security copy will start. The origin directory is $origin_dir and the copy will take place in $destination_dir. Check that the destination directory is the desired one because the data inside this directory will be overwrited.\n
The size of the security copy will be $size_dir \n
Do you want to continue?" 0 0)
then
	echo "The script will make the security copy of $origin_dir in the directory $destination_dir"
else
	echo "Aborting the execution of the script..."
	exit 1

fi


# Security copy:
start=0
overwriten=0
n_files=`find $origin_dir -type f | wc -l`
n_dir=`find $origin_dir -type d | wc -l`

echo "Number of subdirectories in the origin directory: $n_dir"
echo "Number of files in the origin directory: $n_files"
echo "Size of the security copy: $size_dir"
echo -e "\n--- START ---"


echo "Creating directories..."
# Iterate over directories
# Create the directories that are new
IFS=$'\n'
for line in `find $origin_dir -type d`
do
	dir_origin=$line
	dir_dest=${line/$origin_dir/$destination_dir}
	
	if [ ! -d $dir_dest ]; then
		mkdir -p $dir_dest
	fi
done

# Remove the directories that doesn't exists
if [ $remove_dirs -eq 1 ]
then
	for line in `find $destination_dir -type d`
	do
		dir_dest=$line
		dir_origin=${line/$destination_dir/$origin_dir}

		if [ ! -d $dir_origin ]; then
			rm -r $dir_dest
		fi
	done
fi

echo "Copy in progress..."
# Iterate over the files (copy the ones with newer modification date or that are new, remove the ones that doesn't exists)
number=$start
ProgressBar ${number} ${n_files}
number=$(($number + 1))
IFS=$'\n'
for line in `find $origin_dir -type f`
do
	file_origin=$line
	file_dest=${line/$origin_dir/$destination_dir}

	# Do the file exist in destination directory?
	if [ -f $file_dest ]
	then
		# Obtain the modification time since epoch of the files
		modif_time_origin=`stat -c%Y $file_origin` 
		modif_time_dest=`stat -c%Y $file_dest` 

		if [ $modif_time_origin -gt $modif_time_dest ]
		then
			cp $file_origin $file_dest
			overwriten=$(($overwriten + 1))
		fi

		if [ $inverse_copy -eq 1 ] && [ $modif_time_origin -lt $modif_time_dest ]
		then
			cp $file_dest $file_origin
		fi
	else
		cp $file_origin $file_dest
		overwriten=$(($overwriten + 1))
	fi

	ProgressBar ${number} ${n_files}
	number=$(($number + 1))

done

# Remove the files that doesn't exists
if [ $remove_files -eq 1 ]
then
	echo -e "\nRemoving files that doesn't exists..."
	for line in `find $destination_dir -type f`
	do
		file_dest=$line
		file_origin=${line/$destination_dir/$origin_dir}

		if [ ! -f $file_origin ]
		then
			rm -f $file_dest
		fi
	done
fi

echo -e "\nThe security copy has finished correctly!\n$overwriten files has been copied."

