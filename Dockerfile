FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    postgresql-client \
    gzip \
    curl \
    ca-certificates \
    cron \
    unzip \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# rclone
RUN curl https://rclone.org/install.sh | bash

COPY rclone.conf /root/.config/rclone/rclone.conf
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# crontab: permisos 0644, sin +x
COPY crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron
RUN sed -i 's/\r//' /etc/cron.d/backup-cron

RUN mkdir -p /backups

# Este script vuelca el entorno para que cron lo herede
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]