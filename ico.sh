#!/bin/bash

# author: Greg Wojcieszczuk
# Calculate storage overhead (due to protection level) for given file on Isilon OneFS
# ico - Isilon Calculate Overhead
# License: MIT

trap "echo ; echo Cancelling Calculations! ; exit 20" SIGINT SIGTERM

export IFS=$(echo -en "\n\b")

# Checking if running on Isilon Node
osname="$(uname -s)"
if [ "$osname" != "Isilon OneFS" ]; then
	echo "Tool can run only on Isilon Node"
	exit 3
fi

# Checking if runnin as user root
cuserid=$(id -u)
if [ $cuserid -ne 0 ]; then
	echo "Must run as user root"
	exit 4
fi


function showSyntax {

	echo
	echo "$0 -f /ifs/<path to file>"
	echo "$0 -d /ifs/<path to directory>"
	echo
	exit 10


}


function calcFileOverhead {

	# Checking if filename has been provided

	if [ -z ${filelocation}  ]; then
		showSyntax
		exit 1
	fi
	lsSize=$(ls -lnd $filelocation 2> /dev/null | awk '{print $5}')
	if [ -z "$lsSize" ]; then
		echo "No such file"
		exit 2
	fi
	if ls -lnd $filelocation 2> /dev/null | grep '^d' &> /dev/null; then
		echo "Not a directory"
		exit 3
	fi
	
	# Counting 8192 byte (8K) blocks (DSU, FEC) in all protection groups

	tempfile=$(mktemp)
	isi get -DD $filelocation 2> /dev/null | grep -E '^[[:space:]].*[0-9]{1,},[0-9]{1,},[0-9]{1,}:' \
		| awk -F: '{print $2}' | awk -F'#' '{print $2}' > $tempfile
	total=$(awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}' $tempfile)
	rm -f $tempfile

	totalkb=$[$total * 8192]
	isilon_Uses=$(($totalkb / 1024 ))

	file_Size=$(( $lsSize / 1024 ))
	if [ $isilon_Uses -le $file_Size ]; then
		overhead=0.00
	else
		overhead=$(echo "scale=2; ($isilon_Uses - $file_Size) / $file_Size * 100" | bc)
	fi

	protection_data=$(isi get "$filelocation" | tail +2 | awk '{print $1, $2}')
	requested_Protection=$(echo $protection_data | awk '{print $1}')
	actual_Protection=$(echo $protection_data | awk '{print $2}')
	actual_Protection=$(getProtectionLevelCode $actual_Protection)
	storage_efficiency=$(echo "scale=2; $file_Size / $isilon_Uses * 100" | bc)

	echo Summary for: $filelocation
	echo " Isilon Data: $(convertUnits $isilon_Uses)"
	echo " File Size: $(convertUnits $file_Size)"
	echo " Overhead: $overhead %"
	echo " Efficiency: $storage_efficiency %"
	echo " Requested Protection: $requested_Protection"
	echo " Actual Protection: $actual_Protection"

}

function calcDirOverhead {

	checkingdir=$(ls -lnd $dirlocation 2> /dev/null | awk '{print $5}')
	if [ -z "$checkingdir" ]; then
		echo "No such directory"
		exit 2
	fi
	if ls -lnd $dirlocation 2> /dev/null | grep '^[^d]' &> /dev/null; then
		echo "Not directory"
		exit 3
	fi
	# Getting list of files in given directory
	tempfile=$(mktemp)
	tempfile2=$(mktemp)
	echo > $tempfile
	echo > $tempfile2


	allFiles=($(find $dirlocation -type f 2> /dev/null))
	counter=0
	for File in ${allFiles[@]}
	do
		counter=$(($counter + 1))
		echo -en "\r${counter}/${#allFiles[@]}"
		# Counting 8192 byte (8K) blocks (DSU, FEC) in all protection groups
		isi get -DD $File 2> /dev/null | grep -E '^[[:space:]].*[0-9]{1,},[0-9]{1,},[0-9]{1,}:' \
			| awk -F: '{print $2}' | awk -F'#' '{print $2}' >> $tempfile

		lsSize=$(ls -ln $File 2> /dev/null | awk '{print $5}')
		if [ -n "$lsSize" ]; then
			echo $lsSize >> $tempfile2		
		fi
	done
	# Counting total number of 8k blocks for all files
	totalblocks=$(awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}' $tempfile)
	rm -f $tempfile
	totalkb=$[$totalblocks * 8192]
	isilon_Uses=$(($totalkb / 1024 ))

	# Counting total bytes for all files
	totalbytes=$(awk '{for(i=1;i<=NF;i++)s+=$i}END{print s}' $tempfile2)
	rm -f $tempfile2
	
	total_files_kb=$(( $totalbytes / 1024 ))
	if [ $isilon_Uses -le $total_files_kb ]; then
		overhead=0.00
	else
		overhead=$(echo "scale=2; ($isilon_Uses - $total_files_kb) / $total_files_kb * 100" | bc)
	fi

	storage_efficiency=$(echo "scale=2; $total_files_kb / $isilon_Uses * 100" | bc)

	echo
	echo Summary for: $dirlocation
	echo " Isilon Data: $(convertUnits $isilon_Uses)"
	echo " All Files (${#allFiles[@]}) Size: $(convertUnits $total_files_kb)"
	echo " Overhead: $overhead %"
	echo " Efficiency: $storage_efficiency %"

}


function convertUnits {

	_num=$1
	if [ -z $_num ]; then
		echo Invalid value
		exit 30
	fi
	if [[ $_num -lt 1024 ]]; then
		echo -n $_num KiB
		return 0
	fi
	if [[ $_num -ge 1024 ]] && [[ $_num -lt $((1024*1024)) ]]; then
		_v=$(echo "scale=2; $_num / 1024" | bc)
		echo -n $_v MiB
		return 0
	fi
	if [[ $_num -ge $((1024*1024)) ]] && [[ $_num -lt $((1024*1024*1024)) ]]; then
		_v=$(echo "scale=2; $_num / 1024 / 1024" | bc)
		echo -n $_v GiB
		return 0
	fi
	if [[ $_num -ge $((1024*1024*1024)) ]]; then
		_v=$(echo "scale=2; $_num / 1024 / 1024 / 1024" | bc)
		echo -n $_v TiB
		return 0
	fi





}

function getProtectionLevelCode {

	_code="$1"
	if [[ $_code =~ ^[2-8]x$ ]]; then
		protection=$_code
		echo $protection
		return 0
	fi
	if [[ $_code =~ ^[0-9]{1,2}\+[1-4]$ ]]; then
		protection="+$(echo $_code | awk -F+ '{print $2}')n"
		echo $protection
		return 0
	fi
	for a in 2 3 4
	do
		if [[ $_code =~ ^[0-9]{1,2}\+${a}/${a}$ ]]; then
			protection="+${a}d:1n"
			echo $protection
			return 0
		fi
	done
	if [[ $_code =~ ^[0-9]{1,2}\+3/2$ ]]; then
		protection="+3d:1n1d"
		echo $protection
		return 0
	fi
	if [[ $_code =~ ^[0-9]{1,2}\+4/2$ ]]; then
		protection="+4d:2n"
		echo $protection
		return 0
	fi



}


case "$1" in
	-f)
		filelocation="$2"
		calcFileOverhead ;;
	-d)
		dirlocation="$2"
		calcDirOverhead ;;
	*)
		showSyntax ;;
esac



