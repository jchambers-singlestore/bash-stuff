#!/bin/bash

# Remove color from grep output. This will mess with the date command if not unset.
GREP_OPTIONS=

# Define vars
input="./30.tsv"

while IFS= read -r line
do

	dates=`echo $line | grep -o '[0-9]\{10\}'`
	date2=$(date -jur $dates '+%Y-%m-%d %H:%M:%S')
	echo $line | sed "s/[0-9]\{10\}/$date2/g" >> test.txt

done < "$input"
