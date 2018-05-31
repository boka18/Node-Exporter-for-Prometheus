#!/bin/bash

echo "Creating two users";
useradd --no-create-home --shell /bin/false node_exporter

echo "Downloading Node Exporter";

cd ~
curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz

echo "Installing Node Exporter";

tar xvf node_exporter-0.15.2.linux-amd64.tar.gz
cp node_exporter-0.15.2.linux-amd64/node_exporter /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-0.15.2.linux-amd64.tar.gz node_exporter-0.15.2.linux-amd64
touch /etc/systemd/system/node_exporter.service
echo "
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=oneshot
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:8080

[Install]
WantedBy=multi-user.target
" >> /etc/systemd/system/node_exporter.service

echo "Final steps..";
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
