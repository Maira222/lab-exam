#!/bin/bash
set -e

# Update system packages
yum update -y

# Install Nginx
yum install -y nginx

# Generate self-signed certificate
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx-server.key \
  -out /etc/nginx/ssl/nginx-server.crt \
  -subj "/CN=example.com"

# Configure Nginx
cat > /etc/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # HTTP - redirect to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # HTTPS
    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate /etc/nginx/ssl/nginx-server.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx-server.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
}
EOF

# Create custom index.html
cat > /usr/share/nginx/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MairaMalik's Terraform Environment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
        }
        h1 {
            color: #333;
            margin: 0;
        }
        p {
            color: #666;
            font-size: 18px;
            margin: 10px 0 0 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome!</h1>
        <p>This is MairaMalik's Terraform environment</p>
        <p><strong>This instance was created with Terraform</strong></p>
    </div>
</body>
</html>
EOF

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

echo "Nginx configured and running successfully!"
