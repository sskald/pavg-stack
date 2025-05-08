#!/bin/bash

# Variables
GRAFANA_CONF="/etc/grafana"
GRAFANA_DASHBOARDS="/data/grafana/dashboards" # каталог данных
GRAFANA_DEC_DESC_DASHBOARDS="/etc/grafana/provisioning/dashboards" # каталог декларативного описания дашбордов
GRAFANA_DEC_DESC_DS="/etc/grafana/provisioning/datasources" # каталог декларативного описания источников данных
GRAFANA_DATA="/data/grafana"

# PreConfiguration
useradd -M -u 1102 -s /bin/false grafana
mkdir -p $GRAFANA_DEC_DESC_DS
mkdir $GRAFANA_DEC_DESC_DASHBOARDS
mkdir -p $GRAFANA_DASHBOARDS
chown -R grafana $GRAFANA_CONF $GRAFANA_DATA

# Create datasources/main.yml
cat <<EOF> $GRAFANA_DEC_DESC_DS/main.yml
apiVersion: 1
 
datasources:
  - name: Prometheus
    type: prometheus
    version: 1
    access: proxy
    orgId: 1
    basicAuth: false
    editable: false
    url: http://<HOST>:9090
  - name: VictoriaMetrics
    type: prometheus
    version: 1
    access: proxy
    orgId: 1
    basicAuth: false
    editable: false
    url: http://<HOST>:8428
EOF

# Create dashboards/main.yml
cat <<EOF> $GRAFANA_DEC_DESC_DASHBOARDS/main.yml
apiVersion: 1

providers:
- name: 'main'
  orgId: 1
  folder: ''
  type: file
  disableDeletion: false
  editable: True
  options:
    path: /var/lib/grafana/dashboards
EOF

# Add dashboard "Node Exporter Full" in /data/grafana/dashboards
cd ~/ && git clone https://github.com/rfmoz/grafana-dashboards
cp grafana-dashboards/prometheus/node-exporter-full.json $GRAFANA_DASHBOARDS

# Create systemd service
cat <<EOF> /etc/systemd/system/grafana.service
[Unit]
Description=grafana
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm grafana
ExecStart=/usr/bin/docker run \
  --rm \
  --user=1102 \
  --publish=3000:3000 \
  --memory=1024m \
  --volume=/etc/grafana/provisioning:/etc/grafana/provisioning \
  --volume=/data/grafana:/var/lib/grafana \
  --name=grafana \
  grafana/grafana:latest
ExecStop=/usr/bin/docker stop -t 10 grafana

[Install]
WantedBy=multi-user.target
EOF

# Launch
systemctl daemon-reload
systemctl start grafana
systemctl status grafana
systemctl enable grafana
