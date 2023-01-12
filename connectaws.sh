#!/bin/bash

#check if the credentials file exists
if [ ! -f ~/Downloads/credentials ]; then
    echo "Credentials file not found!"
    exit 1
fi

#read the credentials from the file
credentials=$(cat ~/Downloads/credentials)

#loop through each line of the credentials
for line in $credentials
do
    #use a case statement to check if the line starts with "aws_access_key_id"
    case $line in
        "aws_access_key_id"*)
            #export the access key
            export AWS_ACCESS_KEY_ID=${line#*=}
        ;;
        #if the line starts with "aws_secret_access_key"
        "aws_secret_access_key"*)
            #export the secret access key
            export AWS_SECRET_ACCESS_KEY=${line#*=}
        ;;
        #if the line starts with "aws_session_token"
        "aws_session_token"*)
            #export the session token
            export AWS_SESSION_TOKEN=${line#*=}
        ;;
    esac
done

#check if the AWS access and secret key environment variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS access and secret keys not found!"
    exit 1
fi

export key_path=/Users/chambj/.ssh/joeskeyaws_ohio.pem

#check if the key_path environment variable is set
if [ -z "$key_path" ]; then
    echo "Key path not found!"
    exit 1
fi

# List EC2 instances with key name containing jchambers
aws ec2 describe-instances --filters Name=tag:Name,Values='*jchambers*' \
--query 'Reservations[*].Instances[*].[InstanceId, PrivateIpAddress, PublicIpAddress, Tags[?Key==`Name`].Value[]]'

# Prompt user to ssh with chosen key
read -p "Enter the ID of the instance you want to SSH into: " instance_id

#function to ssh into the instance
function ssh_instance {
    # Check if instance is running
    instance_status=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].State.Name" --output text)

    if [ "$instance_status" != "running" ]; then
      echo "Instance is not running. Starting instance..."
      aws ec2 start-instances --instance-ids $instance_id
      echo "Waiting for instance to start..."
      aws ec2 wait instance-running --instance-ids $instance_id
    fi

    sleep 5

    echo "SSHing into instance $instance_id with key $key_path..."
    ssh -i $key_path -o "StrictHostKeyChecking no" ubuntu@$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

    if [ $? -ne 0 ]; then
      echo "Failed to ssh as ubuntu. Trying as ec2-user..."
      ssh -i $key_path -o "StrictHostKeyChecking no" ec2-user@$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
      if [ $? -ne 0 ]; then
        echo "Failed to ssh as ec2-user. Exiting..."
        exit 1
      fi
    fi
}

#call the ssh_instance function
ssh_instance
