#!/bin/sh

set -eu
set -o pipefail

# Configure AWS
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION

echo "AWS configured"

# Configure Minio client
mc alias set minio $MINIO_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

echo "Minio client configured"

# List all buckets
buckets=$(mc ls minio --json | jq -r .key | sed 's/\/$//')

for bucket in $buckets; do
    timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
    
    # Download bucket
    echo "Downloading bucket: $bucket"
    mkdir -p /tmp/${bucket}
    if ! mc cp --recursive minio/${bucket}/ /tmp/${bucket}; then
        [ -n "$SLACK_WEBHOOK_URL" ] && curl -X POST -H 'Content-type: application/json' --data '{"text":"Error in downloading bucket: '"${bucket}"'"}' $SLACK_WEBHOOK_URL
        continue
    fi
    
    # Encrypt bucket
    echo "Encrypting bucket: $bucket"
    cd /tmp/
    tar -cvf ${bucket}_${timestamp}.tar ${bucket}
    echo ${GPG_PASSPHRASE} | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo aes256 -o ${bucket}_${timestamp}.tar.gpg ${bucket}_${timestamp}.tar
    cd -
    
    # Upload to S3
    echo "Uploading bucket to S3: $bucket"
    if ! aws s3 cp /tmp/${bucket}_${timestamp}.tar.gpg s3://$S3_BUCKET_NAME/${bucket}_${timestamp}.tar.gpg; then
        [ -n "$SLACK_WEBHOOK_URL" ] && curl -X POST -H 'Content-type: application/json' --data '{"text":"Error in uploading bucket: '"${bucket}"' to S3"}' $SLACK_WEBHOOK_URL
        continue
    fi
    
    # Remove temp files
    rm -rf /tmp/${bucket}
    rm /tmp/${bucket}_${timestamp}.tar
    rm /tmp/${bucket}_${timestamp}.tar.gpg
done

echo "Backup process completed"

# Delete older backups
if [ -n "$BACKUP_KEEP_DAYS" ]; then
    sec=$((86400*BACKUP_KEEP_DAYS))
    date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
    backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"
    
    echo "Removing old backups from $S3_BUCKET_NAME..."
    aws s3api list-objects \
    --bucket "${S3_BUCKET_NAME}" \
    --query "${backups_query}" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws s3 rm s3://"${S3_BUCKET_NAME}"/'KEY'
    echo "Removal complete."
fi
