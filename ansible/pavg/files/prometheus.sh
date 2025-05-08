#!/bin/bash

# Variables
PROMETHEUS_FOLDER_CONFIG="/etc/prometheus"
PROMETHEUS_FOLDER_DATA="/data/prometheus"

# PreConfiguration
useradd -M -u 1101 -s /bin/false prometheus
mkdir -p $PROMETHEUS_FOLDER_CONFIG/rule_files
mkdir -p /data/prometheus
chown -R prometheus $PROMETHEUS_FOLDER_CONFIG $PROMETHEUS_FOLDER_DATA

# Make conf file
cat <<EOF> $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 30s
 
# remote write to victoriametrics
remote_write:
- url: http://<HOST>:8428/api/v1/write
  remote_timeout: 30s
 
# scrape exporter jobs
scrape_configs:
- job_name: 'prometheus'
  static_configs:
    - targets:
      - <HOST>:9090
- job_name: 'node'
  metrics_path: /metrics
  static_configs:
    - targets:
      - <HOST>:9100
EOF

# Installation
cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=prometheus
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm prometheus
ExecStart=/usr/bin/docker run \
  --rm \
  --user=1101 \
  --publish=9090:9090 \
  --memory=2048m \
  --volume=/etc/prometheus/:/etc/prometheus/ \
  --volume=/data/prometheus/:/prometheus/ \
  --name=prometheus \
  bitnami/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=14d
ExecStop=/usr/bin/docker stop -t 10 prometheus

[Install]
WantedBy=multi-user.target
EOF

# Run
systemctl daemon-reload
systemctl start prometheus
systemctl status prometheus
systemctl enable prometheus
