#!/bin/bash

######## Change to your ssh key and tag ########
export key_path=$HOME/.ssh/joeskeyaws_ohio.pem
export tag=jchambers
################################################

#check if the credentials file exists
if [ ! -f ~/Downloads/credentials ]; then
    echo "Credentials file not found!"
    exit 1
fi

# Function to read the credentials from the file
function read_credentials {
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
}

# Function to validate the AWS credentials
function validate_credentials {
    #check if the AWS access and secret key environment variables are set
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "AWS access and secret keys not found!"
        exit 1
    fi
    #check if the credentials file contains valid AWS keys
    valid_keys=$(aws sts get-caller-identity)
    if [ -z "$valid_keys" ]; then
        echo "AWS keys are not valid!"
        exit 1
    fi
}

# Read the credentials from the file
read_credentials

# Validate the AWS credentials
validate_credentials

#check if the key_path environment variable is set
if [ -z "$key_path" ]; then
    echo "Key path not found!"
    exit 1
fi

# List EC2 instances with key name containing your tag
aws ec2 describe-instances --filters Name=tag:Name,Values='*$tag*' \
--query 'Reservations[*].Instances[*].[InstanceId, PrivateIpAddress, PublicIpAddress, Tags[?Key==`Name`].Value[]]'

# Prompt user to ssh with chosen key
read -p "Enter the ID of the instance you want to SSH into: " instance_id

# Function to validate the instance ID
function validate_instance_id {
    # Check if the provided instance ID is valid
    instance_id_valid=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].InstanceId" --output text)
    if [ -z "$instance_id_valid" ]; then
        echo "Invalid instance ID. Exiting..."
        exit 1
    fi
}

# Validate the instance ID
validate_instance_id

# Function to ssh into the instance
function ssh_instance {
    # Check if instance is running
    instance_status=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].State.Name" --output text)

    if [ "$instance_status" != "running" ]; then
      echo "Instance is not running. Starting instance..."
      aws ec2 start-instances --instance-ids $instance_id
      echo "Waiting for instance to start..."
      aws ec2 wait instance-running --instance-ids $instance_id
    fi

    # Use a loop to check if the instance is running before it attempts to connect
    while [ "$instance_status" != "running" ]
    do
        echo "Waiting for instance to start..."
        sleep 5
        instance_status=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].State.Name" --output text)
    done

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
