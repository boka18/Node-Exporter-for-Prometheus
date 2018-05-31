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
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:19100

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/node_exporter.service

echo "Final steps..";
apt-get -y install iptables-persistent
iptables -I INPUT -p tcp -m state --state NEW --dport 9100 -j ACCEPT
netfilter-persistent save
echo "
server {
    listen 9100 default_server;
    listen [::]:9100 default_server;

    server_name 67.205.173.66;

    location / {
        proxy_pass http://127.0.0.1:19100;
    }

}
" >> /etc/nginx/sites-available/digitalocean;
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
nginx -s reload
