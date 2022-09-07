#!/bin/sh

## Change these varaibles
#############
folder_name="/batchbkups/"
db="joedb"
#############

current_time=$(date "+%Y.%m.%d-%H.%M.%S")

echo "Current Time : $current_time"
echo "Beginning Backup for database $db"

sudo -u memsql mkdir $folder_name/$current_time.$db
singlestore -pSuperSecurePasswordHere -e "backup database $db to '$folder_name/$current_time.$db'"
