#!/bin/bash

######## Change to your info ########
## The 'tag' will be your label or name of your instance

export key_path=$HOME/.ssh/joeskeyaws.pem
export tag=jchambers
export desired_region=us-east-1
export profile=StandardUser-762918031639

# Disabling ls and grep colors so the cachefile is properly captured within this script.
export LS_COLORS=""
unset GREP_OPTIONS

# Check if aws cli is installed
if ! type "aws" > /dev/null; then
  echo "Error: AWS CLI is not installed but is required for this script!"
  echo "Please see install instructions: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi

function refresh_sso_credentials {
    sso_cache_dir="$HOME/.aws/sso/cache"

    latest_sso_cache_file=$(command ls -t $sso_cache_dir | grep json | head -n 1)

    if [ -z "$latest_sso_cache_file" ]; then
        echo "No SSO cache file found. Please login using 'aws sso login'. If you haven't already, configure a profile using 'aws configure sso'. See https://memsql.atlassian.net/wiki/x/QQCcng for details."
        exit 1
    fi

    full_sso_cache_path="$sso_cache_dir/$latest_sso_cache_file"

    if [ ! -f "$full_sso_cache_path" ]; then
        echo "SSO cache file not found at $full_sso_cache_path. Please login using 'aws sso login'. If you haven't already, configure a profile using 'aws configure sso'. See https://memsql.atlassian.net/wiki/x/QQCcng for details."
        exit 1
    fi

    expiration=$(jq -r '.expiresAt' "$full_sso_cache_path")

    if [ -z "$expiration" ]; then
        echo "Unable to read expiration from SSO cache. Please login again or check your cache file: $full_sso_cache_path"
        exit 1
    fi

    expiration_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expiration" +%s)
    current_timestamp=$(date +%s)

    if [ $current_timestamp -gt $expiration_timestamp ]; then
        echo "SSO session has expired. Refreshing credentials..."
        aws sso login --profile $profile
    else
        echo "SSO session is valid."
    fi
}

refresh_sso_credentials

# Set region
aws configure set region $desired_region
echo "Connecting using region $desired_region"

# List EC2 instances with key name containing your tag
(echo "Tag Name|Instance ID|Private IP|Public IP" && aws ec2 describe-instances --filters Name=tag:Name,Values="*$tag*" --query 'Reservations[*].Instances[*].[join(`|`, [Tags[?Key==`Name`].Value | [0], InstanceId, PrivateIpAddress, PublicIpAddress] | map(&to_string(@), @))]' --profile $profile --output text) | column -t -s '|'


# Prompt user to ssh with chosen key
read -p "Enter the ID of the instance you want to SSH into: " instance_id

# Function to validate the instance ID
function validate_instance_id {
    # Check if the provided instance ID is valid
    instance_id_valid=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].InstanceId" --output text --profile $profile)
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
    instance_status=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].State.Name" --output text --profile $profile)

    if [ "$instance_status" != "running" ]; then
      echo "Instance is not running. Starting instance..."
      aws ec2 start-instances --instance-ids $instance_id --profile $profile
      echo "Waiting for instance to start..."
      aws ec2 wait instance-running --instance-ids $instance_id --profile $profile
    fi

    # Use a loop to check if the instance is running before it attempts to connect
    while [ "$instance_status" != "running" ]
    do
        echo "Waiting for instance to start..."
        sleep 15
        instance_status=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].State.Name" --output text --profile $profile)
    done

# Save the IP to a file with the tag name in the users home/.aws/ dir
    FILENAME=$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value]" --output text --profile $profile)
    aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output text --profile $profile > $HOME/.aws/$FILENAME

    echo "SSHing into instance $instance_id with key $key_path..."
    ssh -i $key_path -o "StrictHostKeyChecking no" ubuntu@$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output text --profile $profile)

    if [ $? -ne 0 ]; then
      echo "Failed to ssh as ubuntu. Trying as ec2-user..."
      ssh -i $key_path -o "StrictHostKeyChecking no" ec2-user@$(aws ec2 describe-instances --instance-id $instance_id --query "Reservations[*].Instances[*].PublicIpAddress" --output text --profile $profile)
      if [ $? -ne 0 ]; then
        echo "Failed to ssh as ec2-user. Exiting..."
        exit 1
      fi
    fi
}

#call the ssh_instance function
ssh_instance
