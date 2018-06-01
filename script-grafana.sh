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
" > /etc/systemd/system/node_exporter;

echo "Installing apache2-utils";
apt-get -y install apache2-utils
echo "Please input the username and than the password:";
read username;
htpasswd -c /etc/nginx/.htpasswd $username

echo "Final steps..";
apt-get -y install iptables-persistent
iptables -I INPUT -p tcp -m state --state NEW --dport 9100 -j ACCEPT
netfilter-persistent save
echo "
server {
    listen 9100 default_server;
    listen [::]:9100 default_server;

    location / {
        auth_basic '"Prometheus server authentication"';
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:19100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

}
" >> /etc/nginx/sites-enabled/*;
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
nginx -s reload
