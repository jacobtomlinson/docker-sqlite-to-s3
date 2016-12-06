# Docker SQLite to S3  [![](https://images.microbadger.com/badges/version/jacobtomlinson/sqlite-to-s3.svg)](https://microbadger.com/images/jacobtomlinson/sqlite-to-s3 "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/jacobtomlinson/sqlite-to-s3.svg)](https://microbadger.com/images/jacobtomlinson/sqlite-to-s3 "Get your own image badge on microbadger.com")

This container periodically runs a backup of a SQLite database to an S3 bucket. It also has the ability to restore.

## Usage

### Default cron (1am daily)

```shell
docker run \
    -v /path/to/database.db:/data/sqlite3.db \
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    jacobtomlinson/sqlite-to-s3:latest
```

### Custom cron timing

```shell
docker run \
    -v /path/to/database.db:/data/sqlite3.db \
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    jacobtomlinson/sqlite-to-s3:latest \
    cron "* * * * *"
```

### Run backup

```shell
docker run \
    -v /path/to/database.db:/data/sqlite3.db \
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    jacobtomlinson/sqlite-to-s3:latest \
    backup
```

### Restore

```shell
docker run \
    -v /path/to/database.db:/data/sqlite3.db \
    -e S3_BUCKET=mybackupbucket \
    -e AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
    -e AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
    -e AWS_DEFAULT_REGION=us-west-2 \
    jacobtomlinson/sqlite-to-s3:latest \
    restore
```

## Environment Variables

| Variable        | Description      | Example Usage  | Default   | Optional?  |
| --------------- |:---------------:| -----:| -----:| --------:|
| `S3_BUCKET`               | Name of bucket | `mybucketname` | None | No |
| `S3_KEY_PREFIX` | S3 directory to place files in | `backups` or `backups/sqlite` | None | Yes |
| `AWS_ACCESS_KEY_ID`       | AWS Access key | `AKIAIO...` | None      | Yes (if using instance role) |
| `AWS_SECRET_ACCESS_KEY`   |  AWS Secret Key |  `wJalrXUtnFE...` | None   | Yes (if using instance role) |
| `AWS_DEFAULT_REGION`   | AWS Default Region | `us-west-2`    | `us-west-1`   | Yes |
| `DATABASE_PATH` | Path of database to be backed up (within the container)   | `/myvolume/mydb.db` | `/data/sqlite3.db`   | Yes |
| `BACKUP_PATH` | Path to write the backup (within the container)  | `/myvolume/mybackup.db` | `${DATABASE_PATH}.bak`   | Yes |
