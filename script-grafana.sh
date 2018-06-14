#!/bin/bash

read -p "Select 'n' if you are using NGINX or 'a' if you are using APACHE2 (n/a)?" server

if [[ "$server" = "a" ]]
then
    a2enmod proxy
    a2enmod proxy_http
    a2enmod proxy_balancer
    a2enmod lbmethod_byrequests
    selected_site="$(ls /etc/apache2/sites-enabled)"
    read -p "Do you have supervisord installed and configured? (y/n)?" supervisor
    if [[ "supervisor" = "y" ]]
    then
        ufw allow 9001
        echo "
Listen 9001
<VirtualHost *:9001>
        ServerName supervisord

        CustomLog /var/log/apache2/supervisord_access.log combined
        ErrorLog /var/log/apache2/supervisord_error.log

        ProxyRequests off
        <Proxy *>
                AuthType        Basic
                AuthName        \"Enter Password\"
                AuthUserFile    /var/www/.htpasswd
                Require valid-user
                Allow from all
        </Proxy>

        ProxyErrorOverride On
        ProxyPass / http://127.0.0.1:19001/
        ProxyPassReverse / http://127.0.0.1:19001/
</VirtualHost>
" >> /etc/apache2/sites-enabled/$selected_site;

        echo "

[inet_http_server]
port = *:19001
" >> /etc/supervisor/supervisord.conf;
        systemctl daemon-reload
        systemctl restart supervisor.service
    fi

    systemctl restart apache2.service
# If you have NGINX environment
elif [[ "$server" = "n" ]]
then
        selected_site="$(ls /etc/nginx/sites-enabled)"
fi

read -p "Do you want to install NodeExporter-v0.15.2 (y/n)?" node
if [[ "$node" = "y" ]]
then
        ufw allow 9100
        useradd --no-create-home --shell /bin/false node_exporter
        echo "Downloading NodeExporter-v.0.15.2";
        cd ~
        curl -LO https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz
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
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:19100 --collector.supervisord.url="http://tom:u49t4GqVpNnz@127.0.0.1:19001/RPC"


[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/node_exporter.service;

        if [[ "$server" = "a" ]]
        then
                echo "
Listen 9100
<VirtualHost *:9100>
        ServerName NodeExporter

        CustomLog /var/log/apache2/nodeexporter_access.log combined
        ErrorLog /var/log/apache2/nodeexporter_error.log

        ProxyRequests off
        <Proxy *>
                AuthType        Basic
                AuthName        \"Enter Password\"
                AuthUserFile    /var/www/.htpasswd
                Require valid-user
                Allow from all
        </Proxy>

        ProxyErrorOverride On
        ProxyPass / http://127.0.0.1:19100/
        ProxyPassReverse / http://127.0.0.1:19100/
</VirtualHost>
" >> /etc/apache2/sites-enabled/$selected_site;
        elif [[ "$server" = "n" ]]
        then
                echo "
server {
    listen 9100 default_server;
    listen [::]:9100 default_server;

    location / {
        auth_basic '"Prometheus server authentication"';
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:19100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

}
" >> /etc/nginx/sites-enabled/$selected_site;
nginx -s reload
        fi
fi
systemctl daemon-reload
systemctl start node_exporter.service
systemctl enable node_exporter.service
echo "Script completed";