#!/bin/bash

mkdir -p /data/victoriametrics

# Installation
cat <<EOF> /etc/systemd/system/victoriametrics.service
[Unit]
Description=victoriametrics
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm victoriametrics
ExecStart=/usr/bin/docker run \
  --rm \
  --publish=8428:8428 \
  --volume=/data/victoriametrics:/victoria-metrics-data \
  --name=victoriametrics \
  victoriametrics/victoria-metrics:latest \
  -dedup.minScrapeInterval=60s \
  -retentionPeriod=2
ExecStop=/usr/bin/docker stop -t 10 victoriametrics

[Install]
WantedBy=multi-user.target
EOF

# Run
systemctl daemon-reload
systemctl start victoriametrics
systemctl status victoriametrics
systemctl enable victoriametrics
