FROM alpine:latest

# Set the architecture
ARG TARGETARCH=amd64

# Install required packages
RUN apk add --no-cache \
  curl \
  python3 \
  py3-pip \
  jq \
  gnupg

# Install AWS CLI
RUN pip3 install awscli

# Install Minio Client
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc /usr/local/bin/

# Install go-cron
RUN curl -L https://github.com/ivoronin/go-cron/releases/download/v0.0.5/go-cron_0.0.5_linux_${TARGETARCH}.tar.gz -O && \
    tar xvf go-cron_0.0.5_linux_${TARGETARCH}.tar.gz && \
    rm go-cron_0.0.5_linux_${TARGETARCH}.tar.gz && \
    mv go-cron /usr/local/bin/go-cron && \
    chmod u+x /usr/local/bin/go-cron

# Add our backup script
ADD backup.sh /backup.sh
RUN chmod +x /backup.sh

CMD exec go-cron "$SCHEDULE" /bin/sh backup.sh