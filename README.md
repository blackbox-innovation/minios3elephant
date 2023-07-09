# 🐘 MinioS3Elephant

MinioS3Elephant is a streamlined, Docker-oriented tool committed to ensuring the steadfast backup of your Minio data to AWS S3, without ever missing a beat. With its built-in Slack notifications, it will promptly inform you of every triumph or hiccup along the way. Consider it your tireless elephantine ally, ceaselessly safeguarding your data persistence!

## 🌟 Features

- **Secure Backup**: Encrypts your Minio buckets with GPG before they're backed up to S3.
- **Scheduled Backups**: Uses go-cron to schedule your backup jobs.
- **Slack Notifications**: Informs you via Slack if there's a hiccup during the backup process.

## 🛠 Prerequisites

- Docker and Docker Compose installed on your system.
- Access to a Minio server and an AWS S3 bucket.
- [A Slack webhook URL](https://api.slack.com/messaging/webhooks) for notifications.

## 🚀 Getting Started

1. Update the `docker-compose.yml` file of your application where minio resists and just add the minios3elephant service. Here is an example configuration:
    ```yaml
    version: '3'
    services:
      minio:
        image: minio/minio
        volumes:
          - data:/data
        environment:
          MINIO_ACCESS_KEY: <your-minio-access-key>
          MINIO_SECRET_KEY: <your-minio-secret-key>
        command: server --console-address ":9001" /data
        ports:
        - 9000:9000
        - 9001:9001
      backup:
        image: krystof/minios3elephant
        environment:
          AWS_ACCESS_KEY_ID: <your-aws-access-key>
          AWS_SECRET_ACCESS_KEY: <your-aws-secret-key>
          AWS_REGION: <your-aws-region>
          MINIO_URL: "http://minio:9000"
          MINIO_ACCESS_KEY: <your-minio-access-key>
          MINIO_SECRET_KEY: <your-minio-secret-key>
          S3_BUCKET_NAME: <your-s3-bucket-name>
          SCHEDULE: "<cron-schedule>"
          BUCKET_LIST: "<comma-separated-minio-bucket-names>"
          SLACK_WEBHOOK_URL: "<your-slack-webhook-url>"
          GPG_PASSPHRASE: "<your-gpg-passphrase>"
          BACKUP_KEEP_DAYS: <number of days to keep backups>
    volumes:
      data:
    ```

Remember to replace `<...>` placeholders with your actual values. The `MINIO_URL` environment variable is set to `http://minio:9000` because `minio` is the name of the Minio service in the Docker Compose file and Docker provides automatic service discovery using the service name as the hostname. BUCKET_LIST should be a comma-separated list of the names of the Minio buckets that you want to backup.

### 🔒 How to descrypt the data

1. Download the backup file from you s3 backup location
2. Decrypt with `gpg --batch --yes --passphrase "your-gpg-passphrase" --decrypt -o output.tar your-backup.gpg`


### 🌍 Local Testing with Docker Compose

1.  Clone the repository and navigate to its directory:



```
git clone https://github.com/blackbox-innovation/minios3elephant.git
cd minios3elephant
```

1.  In the `docker-compose.yml` file, replace `your-aws-access-key`, `your-aws-secret-key`, `your-aws-region`, `your-s3-bucket-name`, `your-slack-webhook-url`, and `your-gpg-passphrase` with your actual values.

2.  Start the Docker Compose application:

`docker-compose up -d`

This will start two Docker containers: one for the MinIO service and another for the backup service.

The MinIO service starts a MinIO server listening on the default port of 9000 and mounts a named volume `minio_data` at `/data`. The `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` environment variables are set to `root` and `password` respectively.

The backup service is built from the current directory (with the Dockerfile) and gets environment variables for AWS, MinIO, S3, Slack, GPG passphrase, the schedule, and the bucket list.

1.  You can access the MinIO web interface at <http://localhost:9000>. The access key is `root` and the secret key is `password`. Here you can manually create buckets and upload files for testing.

2.  To see the logs from the backup service, use the following command:


`docker-compose logs backup`

1.  To stop the Docker Compose application, use the following command:


`docker-compose down`

Please note, this setup is meant for local testing and not suitable for production environments. In a production environment, you should use more secure methods to handle your secrets, like Docker secrets or environment variables files.

## 👩‍💻 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

[MIT](https://choosealicense.com/licenses/mit/)
