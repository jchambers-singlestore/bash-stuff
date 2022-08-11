#!/bin/bash
# This script will pull your aws token info from your $HOME/Downloads/credentials file and print your instance IPs.
# It will make an SSH connection to the instance you choose.

export AWS_ACCESS_KEY_ID=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 1p)
export AWS_SECRET_ACCESS_KEY=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 2p)
export AWS_SESSION_TOKEN=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 3p)

export i1=i-04c304083f3b98df2
export i2=i-0449445745458f2fd

state1=`aws ec2 describe-instances --instance-ids $i1 | grep STATE | awk '{print $3}'`
state2=`aws ec2 describe-instances --instance-ids $i2 | grep STATE | awk '{print $3}'`

#TAGS1=`aws ec2 describe-instances --instance-ids i1 | grep TAGS`
#TAGS2=`aws ec2 describe-instances --instance-ids i2 | grep TAGS`

## Ensure instances are running
if [[ "$state1" == 'running' ]] && [[ "$state2" == 'running' ]] ; then
	echo "Instance are already running. Skipping startup"
else
	aws ec2 start-instances --instance-ids $i1 $i2
	echo "Starting instances, waiting 12s."
	sleep 12
fi

## Connection Stuff
echo "Your instances:"
my_array=(`aws ec2 describe-instances --filters "Name=tag-value,Values=jchambers" | grep ASSOCIATION | awk '{print $4}' | uniq`)
i=0
x=1
while [ $i -lt ${#my_array[@]} ]
do
	echo $x ${my_array[$i]}
	i=$(( $i + 1 ))
	x=$(( $x + 1 ))
done

read -p 'Choose a server: ' server
re='^[0-9]+$'

if ! [[ $server =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
fi
ssh -i $HOME/.ssh/joeskeyaws_ohio.pem -o "StrictHostKeyChecking no" ubuntu@`echo ${my_array[$server - 1]}`

# Testing stuff
#echo ${#my_array[@]}
#echo ${my_array[*]}
