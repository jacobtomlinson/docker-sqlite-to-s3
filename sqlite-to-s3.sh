#!/bin/bash

set -e

# Check and set missing environment vars
: ${S3_BUCKET:?"S3_BUCKET env variable is required"}
if [[ -z ${S3_KEY_PREFIX} ]]; then
  export S3_KEY_PREFIX=""
else
  if [ "${S3_KEY_PREFIX: -1}" != "/" ]; then
    export S3_KEY_PREFIX="${S3_KEY_PREFIX}/"
  fi
fi
echo $S3_KEY_PREFIX
export DATABASE_PATH=${DATABASE_PATH:-/data/sqlite3.db}
export BACKUP_PATH=${BACKUP_PATH:-${DATABASE_PATH}.bak}
export DATETIME=$(date "+%Y%m%d%H%M%S")

# Add this script to the crontab and start crond
cron() {
  echo "Starting backup cron job with frequency '$1'"
  echo "$1 $0 backup" > /var/spool/cron/crontabs/root
  crond -f
}

# Dump the database to a file and push it to S3
backup() {
  # Dump database to file
  echo "Backing up $DATABASE_PATH to $BACKUP_PATH"
  sqlite3 $DATABASE_PATH .dump > $BACKUP_PATH
  if [ $? -ne 0 ]; then
    echo "Failed to backup $DATABASE_PATH to $BACKUP_PATH"
    exit 1
  fi

  echo "Sending file to S3"
  # Push backup file to S3
  if aws s3 rm s3://${S3_BUCKET}/${S3_KEY_PREFIX}latest.bak; then
    echo "Removed latest backup from S3"
  else
    echo "No latest backup exists in S3"
  fi
  if aws s3 cp $BACKUP_PATH s3://${S3_BUCKET}/${S3_KEY_PREFIX}latest.bak; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_KEY_PREFIX}latest.bak"
  else
    echo "Backup file failed to upload"
    exit 1
  fi
  if aws s3api copy-object --copy-source ${S3_BUCKET}/${S3_KEY_PREFIX}latest.bak --key ${S3_KEY_PREFIX}${DATETIME}.bak --bucket $S3_BUCKET; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_KEY_PREFIX}${DATETIME}.bak"
  else
    echo "Failed to create timestamped backup"
    exit 1
  fi

  echo "Done"
}

# Pull down the latest backup from S3 and restore it to the database
restore() {
  # Remove old backup file
  if [ -e $BACKUP_PATH ]; then
    echo "Removing out of date backup"
    rm $BACKUP_PATH
  fi
  # Get backup file from S3
  echo "Downloading latest backup from S3"
  if aws s3 cp s3://${S3_BUCKET}/${S3_KEY_PREFIX}latest.bak $BACKUP_PATH; then
    echo "Downloaded"
  else
    echo "Failed to download latest backup"
    exit 1
  fi

  # Restore database from backup file
  echo "Running restore"
  if [ -e $DATABASE_PATH ]; then
    echo "Moving out of date database aside"
    mv $DATABASE_PATH ${DATABASE_PATH}.old
  fi
  if sqlite3 $DATABASE_PATH < $BACKUP_PATH; then
    echo "Successfully restored"
    if [ -e ${DATABASE_PATH}.old ]; then
      echo "Cleaning up out of date database"
      rm ${DATABASE_PATH}.old
    fi
  else
    echo "Restore failed"
    if [ -e ${DATABASE_PATH}.old ]; then
      echo "Moving out of date database back, hopefully it's better than nothing"
      mv ${DATABASE_PATH}.old $DATABASE_PATH
    fi
    exit 1
  fi
  echo "Done"

}

# Handle command line arguments
case "$1" in
  "cron")
    cron "$2"
    ;;
  "backup")
    backup
    ;;
  "restore")
    restore
    ;;
  *)
    echo "Invalid command '$@'"
    echo "Usage: $0 {backup|restore|cron <pattern>}"
esac
