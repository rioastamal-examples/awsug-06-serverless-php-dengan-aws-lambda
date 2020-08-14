#!/bin/bash

# Create mailhog user
useradd -d /opt/mailhog -m -s /bin/bash mailhog 2>/dev/null

# Create directory for mailhog binary and storage
sudo -u mailhog mkdir -p /opt/mailhog/{bin,storage}

# Download mailhog from github release page
MAILHOG_VERSION=1.0.0
MAILHOG_DOWNLOAD_URL=https://github.com/mailhog/MailHog/releases/download/v${MAILHOG_VERSION}/MailHog_linux_amd64

# Download the binary if not exists
[ ! -f /opt/mailhog/bin/mailhog ] && {
  curl -s -L -o /opt/mailhog/bin/mailhog $MAILHOG_DOWNLOAD_URL
}

chmod +x /opt/mailhog/bin/mailhog

[ ! -x /usr/sbin/nginx ] && {
  apt-get update
  apt-get install -y nginx
}

# Nginx Virtual Host
cat <<EOF > /etc/nginx/sites-available/mailhog.teknocerdas.com.conf
server {
    # Add index.php to the list if you are using PHP
    index index.html index.htm index.nginx-debian.html;

    server_name mailhog.teknocerdas.com;

    location /api/v2/websocket {
        proxy_pass http://127.0.0.1:8025;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    location / {
        auth_basic "Administrator Access";
        auth_basic_user_file /etc/nginx/nginx.passwd;
        proxy_pass http://127.0.0.1:8025;
    }

    listen 80;
}
EOF

ln -fs /etc/nginx/sites-available/mailhog.teknocerdas.com.conf /etc/nginx/sites-enabled/mailhog.teknocerdas.com.conf

# Nginx Password
[ ! -f /etc/nginx/nginx.passwd ] && {
  echo teknocerdas:$( openssl passwd -apr1 "orang.cerdas" ) > /etc/nginx/nginx.passwd
}

# SystemD
cat <<EOF > /etc/systemd/system/mailhog.service
[Unit]
Description=Mailhog fake mailserver
After=network.target

[Service]
Type=simple
User=mailhog
Group=mailhog
ExecStart=/opt/mailhog/bin/mailhog --storage maildir --maildir-path /opt/mailhog/storage/ -ui-bind-addr "127.0.0.1:8025" -api-bind-addr "127.0.0.1:8025" -smtp-bind-addr "0.0.0.0:1025"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable mailhog.service
systemctl start mailhog.service
systemctl restart nginx.service