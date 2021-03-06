#!/bin/sh

##############################################################
#  Script     : ebs_snapshot.sh
#  Author     : dayski
#  Date       : 20130710
#  Description: * This script creates an ebs snapshot of a given volume
#               * Previous snapshots of current month, if exists
#               will be deleted. It will keep monthly snapshots,
#               will not delete snapshots created on last day of the month
#               * Logs will be create in the tmp folder
#  Usage      : sh ebs_snapshot.sh volume_id description_prefix
#  notes      : ensure that aws ec2 tools are configured
##############################################################

# usage check
# ensure that the vol_id and prefix are passed as arguments
[ $# -eq 0 ] && { echo "Usage: $0 VOL_ID DESC_PREFIX" ; exit 1; }

# set the config variables
VOL_ID=${1}
DESC_PREFIX=${2}
LOG=/tmp/ebs_snapshot_${VOL_ID}.log

# get the latest date - for snapshot description
yymm=$(date +"%Y%m")
td=$(date +"%d")
yd=$(($td-1))

# get the desc for todays snapshot
desc="${DESC_PREFIX}${yymm}${td}"

# run the command
echo "$(date +%Y%m%d-%T) ec2-create-snapshot -d $desc $VOL_ID" | tee -a $LOG
ec2-create-snapshot -d $desc $VOL_ID | tee -a $LOG

# exit if there are errors
if [ $? -ne 0 ]
then
  echo "$(date +%Y%m%d-%T) $1" | tee -a $LOG
  exit 1
fi

# check for older snapshot and delete them
yd=$(($td-1))
yd_desc="${DESC_PREFIX}${yymm}${yd}"

# ignore if today is first of the month
if [ $yd -ne 0 ]
then
  # get the snapshot id for yesterday
  echo "$(date +%Y%m%d-%T) ec2-describe-snapshots -o self --filter description=$yd_desc --filter volume-id=$VOL_ID"
  snap_id=$(ec2-describe-snapshots -o self --filter "description=$yd_desc" --filter "volume-id=$VOL_ID" | awk '{print $2}')
  
  echo "$(date +%Y%m%d-%T) Snapshots to delete $snap_id" | tee -a $LOG
  
  # delete the older snapshots
  for sid in $snap_id
  do
    echo "$(date +%Y%m%d-%T) ec2-delete-snapshot $Sid" | tee -a $LOG
    ec2-delete-snapshot $sid | tee -a $LOG
  done
fi
