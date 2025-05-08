#!/bin/bash

# Make directory 
sudo mkdir /etc/alertmanager

# =================Pre-configuration============
cat <<EOF> /etc/alertmanager/alertmanager.yml
global:
 resolve_timeout: 5m
 telegram_api_url: "https://api.telegram.org"

templates:
  - '/etc/alertmanager/*.tmpl'

receivers:
- name: 'telegram'
  telegram_configs:
  - chat_id: <ID>
    bot_token: '<TOKEN>'
    api_url: 'https://api.telegram.org'
    send_resolved: true
    parse_mode: HTML
    message: '{{ template "telegram.default" . }}'


route:
  group_by: ['alertname']
  group_wait: 15s
  group_interval: 30s
  repeat_interval: 12h
  receiver: 'telegram'
EOF

# =================Installation====================
cat <<EOF> /etc/systemd/system/alertmanager.service
[Unit]
Description=alertmanager
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm alertmanager
ExecStart=/usr/bin/docker run   --rm   --publish=9093:9093   --memory=512m   --volume=/etc/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro   --volume=/data/alertmanager:/alertmanager/data --volume=/etc/alertmanager:/etc/alertmanager    --name=alertmanager   prom/alertmanager:latest   --config.file=/etc/alertmanager/alertmanager.yml
ExecStop=/usr/bin/docker stop -t 10 alertmanager

[Install]
WantedBy=multi-user.target
EOF

# ===================Run=====================
sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl status alertmanager
sudo systemctl enable alertmanager
