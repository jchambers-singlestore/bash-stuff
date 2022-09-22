#!/bin/bash

# MacOS ONLY! This will not work on Linux.
# This script will find any 10-digit number and convert it to a date/time stamp format YYYY-MM-DD HH:MM:SS.
# Useful for the cluster report's informationSchemaPipelines outputs.
#
# CAUTION: Since we can the entire text file for 10-digit numbers, we could possibly convert a customer's number string into a date/time format.
#
#
# By: Joe Chambers

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Use this script to find all unix timestamps and convert them to YYYY-MM-DD HH:MM:SS"
   echo
   echo "Syntax: ./converttime.sh <input file>"
   echo
}


############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Remove color from grep output. This will mess with the date command if not unset.
GREP_OPTIONS=

# Define vars
input=$1

############################################################
# Check that the user provides an input file               #
############################################################

if [ -f $1 ]
then
        echo "Converting the timestamps in $1."
else
        echo "The given argument does not exist on the file system."
	echo "Syntax: ./converttime.sh <input file>"
	exit 1
fi

if [[ $# -eq 0 ]] ; then
	echo "Error: Proivde an input file."
	echo "Syntax: ./converttime.sh <input file>"
	exit 1
fi

############################################################
# Do work                                                  #
############################################################

while IFS= read -r line
do

	dates=`echo $line | grep -o '[0-9]\{10\}'`
	date2=$(date -jur $dates '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
	echo $line | sed "s/[0-9]\{10\}/$date2/g" >> ./$input.timestampConverted.txt

done < "$input"

echo "Converted file: $input.timestampConverted.txt"
