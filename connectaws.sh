#!/bin/bash
# This script will pull your aws token info from your $HOME/Downloads/credentials file and print your instance IPs.
# It will make an SSH connection to the instance you choose.

AWS_ACCESS_KEY_ID=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 1p)
AWS_SECRET_ACCESS_KEY=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 2p)
AWS_SESSION_TOKEN=$(cat $HOME/Downloads/credentials | cut -d " " -f 3 | grep -v default | sed -n 3p)

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

ssh -i $HOME/.ssh/yourpemfile.pem ubuntu@`echo ${my_array[$server - 1]}`

# Testing stuff
#echo ${#my_array[@]}
#echo ${my_array[*]}
